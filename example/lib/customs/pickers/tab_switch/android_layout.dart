import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wechat_assets_picker/src/constants/constants.dart';
import 'package:wechat_assets_picker/src/constants/extensions.dart';
import 'package:wechat_assets_picker/src/widget/fixed_appbar.dart';
import 'package:wechat_assets_picker/src/widget/gaps.dart';
import 'package:wechat_assets_picker/src/widget/platform_progress_indicator.dart';
import 'package:wechat_assets_picker/src/widget/scale_text.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'file_pick_page.dart';
import "package:wechat_camera_picker/wechat_camera_picker.dart";

const _pageTabs = [
  Tab(text: "文件"),
  Tab(text: "拍摄"),
];

class AndroidLayout extends StatefulWidget {
  final NewCustomAssetPickerBuilderDelegate delegate;

  const AndroidLayout(this.delegate, {Key? key}) : super(key: key);

  @override
  State<AndroidLayout> createState() => _AndroidLayoutState();
}

class _AndroidLayoutState extends State<AndroidLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PageController _pageController = PageController();

  @override
  initState() {
    super.initState();
    _tabController = TabController(length: _pageTabs.length, vsync: this)
      ..addListener(() {
        _pageController.animateToPage(_tabController.index,
            curve: Curves.easeIn, duration: const Duration(milliseconds: 150));
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.index = index;
            },
            children: [
              Consumer<ProviderAggregate>(
                builder:
                    (BuildContext context, ProviderAggregate pa, Widget? child) =>
                        CNP<DAPP>.value(
                  value: pa.selectedProvider,
                  builder: (BuildContext context, _) => FixedAppBarWrapper(
                    appBar: widget.delegate.appBar(context),
                    body: Selector<DAPP, bool>(
                      selector: (_, DAPP provider) => provider.hasAssetsToDisplay,
                      builder: (_, bool hasAssetsToDisplay, __) {
                        final bool shouldDisplayAssets = hasAssetsToDisplay ||
                            (widget.delegate.allowSpecialItemWhenEmpty &&
                                widget.delegate.specialItemPosition !=
                                    SpecialItemPosition.none);
                        return AnimatedSwitcher(
                          duration: widget.delegate.switchingPathDuration,
                          child: shouldDisplayAssets
                              ? SelectFilePage(widget.delegate)
                              : widget.delegate.loadingIndicator(context),
                        );
                      },
                    ),
                  ),
                ),
              ),
              CameraPicker(),
            ],
          ),
        ),
        TabBar(tabs: _pageTabs, controller: _tabController),
      ],
    );
  }
}

class SelectFilePage extends StatefulWidget {
  final NewCustomAssetPickerBuilderDelegate delegate;

  const SelectFilePage(this.delegate, {Key? key}) : super(key: key);

  @override
  State<SelectFilePage> createState() => _SelectFilePageState();
}

const Map<int, RequestType> _map = {
  0: RequestType.common,
  1: RequestType.video,
  2: RequestType.image
};
const _tabs = [
  Tab(text: "全部"),
  Tab(text: "视频"),
  Tab(text: "图片"),
];

class _SelectFilePageState extends State<SelectFilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        final int index = _tabController.index;
        final ProviderAggregate pa = context.read<ProviderAggregate>();
        pa.requestType = _map[index]!;
      });
  }

  @override
  Widget build(BuildContext context) {
    final NewCustomAssetPickerBuilderDelegate delegate = widget.delegate;
    return Stack(
      children: <Widget>[
        RepaintBoundary(
          child: Consumer<ProviderAggregate>(
            builder: (BuildContext context, ProviderAggregate pa, _) => Column(
              children: <Widget>[
                TabBar(
                  controller: _tabController,
                  tabs: _tabs,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      CNP<DAPP>.value(
                        value: pa.common,
                        child: delegate.assetsGridBuilder(context),
                      ),
                      CNP<DAPP>.value(
                        value: pa.video,
                        child: delegate.assetsGridBuilder(context),
                      ),
                      CNP<DAPP>.value(
                        value: pa.image,
                        child: delegate.assetsGridBuilder(context),
                      ),
                    ],
                  ),
                ),
                if (!delegate.isSingleAssetMode && delegate.isPreviewEnabled)
                  delegate.bottomActionBar(context),
              ],
            ),
          ),
        ),
        delegate.pathEntityListBackdrop(context),
        delegate.pathEntityListWidget(context),
      ],
    );
  }
}
