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

class AndroidLayoutWidget extends StatefulWidget {
  final NewCustomAssetPickerBuilderDelegate delegate;

  const AndroidLayoutWidget(this.delegate);

  @override
  State<AndroidLayoutWidget> createState() => _AndroidLayoutWidgetState();
}

const Map<int, RequestType> _map = {
  0: RequestType.common,
  1: RequestType.video,
  2: RequestType.image
};

class _AndroidLayoutWidgetState extends State<AndroidLayoutWidget>
    with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this)
      ..addListener(() {
        final int index = _controller.index;
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
                  controller: _controller,
                  tabs: const [
                    Tab(text: "全部"),
                    Tab(text: "视频"),
                    Tab(text: "图片"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
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
