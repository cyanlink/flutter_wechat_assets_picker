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

import 'android_layout.dart';


Future<List<AssetEntity>?> customPick(BuildContext context) {
  final DAPP provider = DAPP(requestType: RequestType.common);
  final NewCustomAssetPickerBuilderDelegate delegate =
  NewCustomAssetPickerBuilderDelegate(
    initialPermission: PermissionState.notDetermined,);
  /*MyAssetPickerBuilderDelegate(
        provider: provider, initialPermission: PermissionState.notDetermined);*/
  return AssetPicker.pickAssetsWithDelegate(context,
    delegate: delegate, provider: provider,);
}

Future<List<AssetEntity>?> newCustomPick(BuildContext context, List<AssetEntity> selectedAssets) async {
  final NewCustomAssetPickerBuilderDelegate delegate =
  NewCustomAssetPickerBuilderDelegate(
    initialPermission: PermissionState.notDetermined,
  );

  final DAPP iap = DAPP(requestType: RequestType.image);
  final DAPP vap = DAPP(requestType: RequestType.video);
  final DAPP cap = DAPP(requestType: RequestType.common);
  final ProviderAggregate pa =
  ProviderAggregate(image: iap, video: vap, common: cap);
  pa.selectedAssets = selectedAssets;
  return AssetPickerExtension.pickAssetsWithDelegateAggregatedProvider(
    context,
    delegate: delegate,
    providerAggregate: pa,
  );
}

class ProviderAggregate extends ChangeNotifier {
  ProviderAggregate(
      {required this.image,
        required this.video,
        required this.common,
        this.maxAssets = 9,}) {
    _map = Map<RequestType, DAPP>.unmodifiable(<RequestType, DAPP>{
      RequestType.common: common,
      RequestType.video: video,
      RequestType.image: image
    });

  }

  DAPP image;
  DAPP video;
  DAPP common;

  int maxAssets;

  RequestType _type = RequestType.common;

  late final Map<RequestType, DAPP> _map;

  RequestType get requestType => _type;

  set requestType(RequestType type) {
    if (type == _type) {
      return;
    } else {
      _type = type;
      notifyListeners();
    }
  }

  ///To change it, set [requestType].
  DAPP get selectedProvider => _map[_type]!;

  List<AssetEntity> _selectedAssets = <AssetEntity>[];

  List<AssetEntity> get selectedAssets => _selectedAssets;

  set selectedAssets(List<AssetEntity> value) {
    if (value == _selectedAssets) {
      return;
    }
    _selectedAssets = List<AssetEntity>.from(value);
    image.selectedAssets = _selectedAssets;
    video.selectedAssets = _selectedAssets;
    common.selectedAssets = _selectedAssets;
    notifyListeners();
  }

  void selectAsset(AssetEntity item, DAPP provider) {
    if (selectedAssets.length == maxAssets || selectedAssets.contains(item)) {
      return;
    }
    final List<AssetEntity> _set = List<AssetEntity>.from(selectedAssets);
    _set.add(item);
    selectedAssets = _set;
    provider.selectAsset(item);
  }

  void unSelectAsset(AssetEntity item, DAPP provider) {
    final List<AssetEntity> _set = List<AssetEntity>.from(selectedAssets);
    _set.remove(item);
    selectedAssets = _set;
    provider.unSelectAsset(item);
  }

  bool get isSelectedNotEmpty => _selectedAssets.isNotEmpty;


  /// If path switcher opened.
  /// 是否正在进行路径选择
  bool _isSwitchingPath = false;

  bool get isSwitchingPath => _isSwitchingPath;

  set isSwitchingPath(bool value) {
    if (value == _isSwitchingPath) {
      return;
    }
    _isSwitchingPath = value;
    notifyListeners();
  }
}

extension AssetPickerExtension on AssetPicker {
  /// Call the picker with provided [delegate] and [provider].
  /// 通过指定的 [delegate] 和 [provider] 调用选择器
  static Future<List<Asset>?>
  pickAssetsWithDelegateAggregatedProvider<Asset, Path>(
      BuildContext context, {
        required AssetPickerBuilderDelegate<Asset, Path> delegate,
        required ProviderAggregate providerAggregate,
        bool useRootNavigator = true,
        Curve routeCurve = Curves.easeIn,
        Duration routeDuration = const Duration(milliseconds: 300),
      }) async {
    await AssetPicker.permissionCheck();

    final Widget picker = CNP<ProviderAggregate>.value(
      value: providerAggregate,
      child: AssetPicker<Asset, Path>(
        key: Constants.pickerKey,
        builder: delegate,
      ),
    );

    final dynamic result = await Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    ).push<dynamic>(
      AssetPickerPageRoute<dynamic>(
        builder: picker,
        transitionCurve: routeCurve,
        transitionDuration: routeDuration,
      ),
    );
    List<Asset>? list;
    if(result is Asset) {
      list = [result];
    }else if(result is List<Asset>){
    list = result;
    }
    return list!;
  }
}

class NewCustomAssetPickerBuilderDelegate
    extends AssetPickerBuilderDelegate<AssetEntity, AssetPathEntity> {
  NewCustomAssetPickerBuilderDelegate({
    required PermissionState initialPermission,
    int gridCount = 4,
    Color? themeColor,
    AssetsPickerTextDelegate? textDelegate,
    ThemeData? pickerTheme,
    SpecialItemPosition specialItemPosition = SpecialItemPosition.none,
    WidgetBuilder? specialItemBuilder,
    IndicatorBuilder? loadingIndicatorBuilder,
    bool allowSpecialItemWhenEmpty = false,
    bool keepScrollOffset = false,
    AssetSelectPredicate<AssetEntity>? selectPredicate,
    bool? shouldRevertGrid,
    this.gridThumbSize = Constants.defaultGridThumbSize,
    this.previewThumbSize,
    this.specialPickerType,
  })  : assert(
  pickerTheme == null || themeColor == null,
  'Theme and theme color cannot be set at the same time.',
  ),
        super(
        initialPermission: initialPermission,
        gridCount: gridCount,
        themeColor: themeColor,
        textDelegate: textDelegate,
        pickerTheme: pickerTheme,
        specialItemPosition: specialItemPosition,
        specialItemBuilder: specialItemBuilder,
        loadingIndicatorBuilder: loadingIndicatorBuilder,
        allowSpecialItemWhenEmpty: allowSpecialItemWhenEmpty,
        keepScrollOffset: keepScrollOffset,
        selectPredicate: selectPredicate,
        shouldRevertGrid: shouldRevertGrid,
      );

  /// Thumbnail size in the grid.
  /// 预览时网络的缩略图大小
  ///
  /// This only works on images and videos since other types does not have to
  /// request for the thumbnail data. The preview can speed up by reducing it.
  /// 该参数仅生效于图片和视频类型的资源，因为其他资源不需要请求缩略图数据。
  /// 预览图片的速度可以通过适当降低它的数值来提升。
  ///
  /// This cannot be `null` or a large value since you shouldn't use the
  /// original data for the grid.
  /// 该值不能为空或者非常大，因为在网格中使用原数据不是一个好的决定。
  final int gridThumbSize;

  @override
  bool get isSingleAssetMode => false;

  /// Preview thumbnail size in the viewer.
  /// 预览时图片的缩略图大小
  ///
  /// This only works on images and videos since other types does not have to
  /// request for the thumbnail data. The preview can speed up by reducing it.
  /// 该参数仅生效于图片和视频类型的资源，因为其他资源不需要请求缩略图数据。
  /// 预览图片的速度可以通过适当降低它的数值来提升。
  ///
  /// Default is `null`, which will request the origin data.
  /// 默认为空，即读取原图。
  final List<int>? previewThumbSize;

  /// The current special picker type for the picker.
  /// 当前特殊选择类型
  ///
  /// Several types which are special:
  /// * [SpecialPickerType.wechatMoment] When user selected video, no more images
  /// can be selected.
  /// * [SpecialPickerType.noPreview] Disable preview of asset; Clicking on an
  /// asset selects it.
  ///
  /// 这里包含一些特殊选择类型：
  /// * [SpecialPickerType.wechatMoment] 微信朋友圈模式。当用户选择了视频，将不能选择图片。
  /// * [SpecialPickerType.noPreview] 禁用资源预览。多选时单击资产将直接选中，单选时选中并返回。
  final SpecialPickerType? specialPickerType;

  /// [Duration] when triggering path switching.
  /// 切换路径时的动画时长
  Duration get switchingPathDuration => const Duration(milliseconds: 300);

  /// [Curve] when triggering path switching.
  /// 切换路径时的动画曲线
  Curve get switchingPathCurve => Curves.easeInOutQuad;

  /// Whether the [SpecialPickerType.wechatMoment] is enabled.
  /// 当前是否为微信朋友圈选择模式
  bool get isWeChatMoment =>
      specialPickerType == SpecialPickerType.wechatMoment;

  /// Whether the preview of assets is enabled.
  /// 资源的预览是否启用
  bool get isPreviewEnabled => specialPickerType != SpecialPickerType.noPreview;

  @override
  Future<void> onLimitedAssetsUpdated(
      MethodCall call, BuildContext context,) async {
    final ProviderAggregate pa= context.read<ProviderAggregate>();
    if (isPermissionLimited) {
      return;
    }
    if (pa.selectedProvider.currentPathEntity != null) {
      final AssetPathEntity? _currentPathEntity = pa.selectedProvider.currentPathEntity;
      if (_currentPathEntity is AssetPathEntity) {
        await _currentPathEntity.refreshPathProperties();
      }
      await pa.selectedProvider.switchPath(_currentPathEntity);
    }
  }

  @override
  Future<void> selectAsset(
      BuildContext context,
      AssetEntity asset,
      bool selected,
      ) async {
    final DAPP provider = context.read<DAPP>();
    final ProviderAggregate pa = context.read<ProviderAggregate>();
    final bool? selectPredicateResult = await selectPredicate?.call(
      context,
      asset,
      selected,
    );
    if (selectPredicateResult == false) {
      return;
    }
    if (selected) {
      pa.unSelectAsset(asset, provider);
      return;
    }
    if (isSingleAssetMode) {
      provider.selectedAssets.clear();
    }
    pa.selectAsset(asset, provider);
    if (isSingleAssetMode && !isPreviewEnabled) {
      Navigator.of(context).maybePop(pa.selectedAssets);
    }
  }

  Future<void> _pushAssetToViewer(
      BuildContext context,
      int index,
      AssetEntity asset,
      ) async {
    final DAPP provider = context.read<DAPP>();
    bool selectedAllAndNotSelected() =>
        !provider.selectedAssets.contains(asset) &&
            provider.selectedMaximumAssets;
    bool selectedPhotosAndIsVideo() =>
        isWeChatMoment &&
            asset.type == AssetType.video &&
            provider.selectedAssets.isNotEmpty;
    // When we reached the maximum select count and the asset
    // is not selected, do nothing.
    // When the special type is WeChat Moment, pictures and videos cannot
    // be selected at the same time. Video select should be banned if any
    // pictures are selected.
    if (selectedAllAndNotSelected() || selectedPhotosAndIsVideo()) {
      return;
    }
    final List<AssetEntity> _current;
    final List<AssetEntity>? _selected;
    final int _index;
    if (isWeChatMoment) {
      if (asset.type == AssetType.video) {
        _current = <AssetEntity>[asset];
        _selected = null;
        _index = 0;
      } else {
        _current = provider.currentAssets
            .where((AssetEntity e) => e.type == AssetType.image)
            .toList();
        _selected = provider.selectedAssets;
        _index = _current.indexOf(asset);
      }
    } else {
      _current = provider.currentAssets;
      _selected = provider.selectedAssets;
      _index = index;
    }
    final List<AssetEntity>? result = await AssetPickerViewer.pushToViewer(
      context,
      currentIndex: _index,
      previewAssets: _current,
      themeData: theme,
      previewThumbSize: previewThumbSize,
      selectedAssets: _selected,
      selectorProvider: provider,
      specialPickerType: specialPickerType,
      maxAssets: provider.maxAssets,
      shouldReversePreview: isAppleOS,
    );
    if (result != null) {
      Navigator.of(context).maybePop(result);
    }
  }

  static const Map<int, RequestType> _map = {
    0: RequestType.common,
    1: RequestType.video,
    2: RequestType.image
  };

  @override
  Widget androidLayout(BuildContext context) {
    return AndroidLayout(this);
  }

  @override
  PreferredSizeWidget appBar(BuildContext context) {
    return FixedAppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      centerTitle: isAppleOS,
      title: Semantics(
        onTapHint: textDelegate.sActionSwitchPathLabel,
        child: pathEntitySelector(context),
      ),
      leading: backButton(context),
      // Condition for displaying the confirm button:
      // - On Android, show if preview is enabled or if multi asset mode.
      //   If no preview and single asset mode, do not show confirm button,
      //   because any click on an asset selects it.
      // - On iOS, show if no preview and multi asset mode. This is because for iOS
      //   the [bottomActionBar] has the confirm button, but if no preview,
      //   [bottomActionBar] is not displayed.
      actions: (!isAppleOS || !isPreviewEnabled) &&
          (isPreviewEnabled || !isSingleAssetMode)
          ? <Widget>[confirmButton(context)]
          : null,
      actionsPadding: const EdgeInsetsDirectional.only(end: 14),
      blurRadius: isAppleOS ? appleOSBlurRadius : 0,
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) {
    Widget _gridLayout(BuildContext context) {
      return Selector<ProviderAggregate, bool>(
        selector: (_, ProviderAggregate p) => p.isSwitchingPath,
        builder: (_, bool isSwitchingPath, __) => Semantics(
          excludeSemantics: isSwitchingPath,
          child: RepaintBoundary(
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: assetsGridBuilder(context)),
                if ((!isSingleAssetMode || isAppleOS) && isPreviewEnabled)
                  Positioned.fill(
                    top: null,
                    child: bottomActionBar(context),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _layout(BuildContext context) {
      return Stack(
        children: <Widget>[
          Positioned.fill(
            child: Selector<DAPP, bool>(
              selector: (_, DAPP p) => p.hasAssetsToDisplay,
              builder: (_, bool hasAssetsToDisplay, __) {
                final Widget _child;
                final bool shouldDisplayAssets = hasAssetsToDisplay ||
                    (allowSpecialItemWhenEmpty &&
                        specialItemPosition != SpecialItemPosition.none);
                if (shouldDisplayAssets) {
                  _child = Stack(
                    children: <Widget>[
                      _gridLayout(context),
                      pathEntityListBackdrop(context),
                      pathEntityListWidget(context),
                    ],
                  );
                } else {
                  _child = loadingIndicator(context);
                }
                return AnimatedSwitcher(
                  duration: switchingPathDuration,
                  child: _child,
                );
              },
            ),
          ),
          Semantics(sortKey: const OrdinalSortKey(0), child: appBar(context)),
        ],
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: permissionOverlayHidden,
      builder: (_, bool value, Widget? child) {
        if (value) {
          return child!;
        }
        return Semantics(
          excludeSemantics: true,
          sortKey: const OrdinalSortKey(1),
          child: child,
        );
      },
      child: _layout(context),
    );
  }

  @override
  Widget assetsGridBuilder(BuildContext context) {
    return Selector<DAPP, AssetPathEntity?>(
      selector: (_, DAPP p) => p.currentPathEntity,
      builder: (_, AssetPathEntity? path, __) {
        // First, we need the count of the assets.
        int totalCount = path?.assetCount ?? 0;
        // If user chose a special item's position, add 1 count.
        if (specialItemPosition != SpecialItemPosition.none &&
            path?.isAll == true) {
          totalCount += 1;
        }
        // Then we use the [totalCount] to calculate placeholders we need.
        final int placeholderCount;
        if (effectiveShouldRevertGrid && totalCount % gridCount != 0) {
          // When there are left items that not filled into one row,
          // filled the row with placeholders.
          placeholderCount = gridCount - totalCount % gridCount;
        } else {
          // Otherwise, we don't need placeholders.
          placeholderCount = 0;
        }
        // Calculate rows count.
        final int row = (totalCount + placeholderCount) ~/ gridCount;
        // Here we got a magic calculation. [itemSpacing] needs to be divided by
        // [gridCount] since every grid item is squeezed by the [itemSpacing],
        // and it's actual size is reduced with [itemSpacing / gridCount].
        final double dividedSpacing = itemSpacing / gridCount;
        final double topPadding = context.topPadding + kToolbarHeight;

        Widget _sliverGrid(BuildContext ctx, List<AssetEntity> assets) {
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (_, int index) => Builder(
                builder: (BuildContext c) {
                  if (effectiveShouldRevertGrid) {
                    if (index < placeholderCount) {
                      return const SizedBox.shrink();
                    }
                    index -= placeholderCount;
                  }
                  return MergeSemantics(
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: assetGridItemBuilder(c, index, assets),
                    ),
                  );
                },
              ),
              childCount: assetsGridItemCount(
                context: ctx,
                assets: assets,
                placeholderCount: placeholderCount,
              ),
              findChildIndexCallback: (Key? key) {
                if (key is ValueKey<String>) {
                  return findChildIndexBuilder(
                    id: key.value,
                    assets: assets,
                    placeholderCount: placeholderCount,
                  );
                }
                return null;
              },
              // Explicitly disable semantic indexes for custom usage.
              addSemanticIndexes: false,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: itemSpacing,
              crossAxisSpacing: itemSpacing,
            ),
          );
        }

        return LayoutBuilder(
          builder: (BuildContext c, BoxConstraints constraints) {
            final double itemSize = constraints.maxWidth / gridCount;
            // Check whether all rows can be placed at the same time.
            final bool onlyOneScreen = row * itemSize <=
                constraints.maxHeight -
                    context.bottomPadding -
                    topPadding -
                    permissionLimitedBarHeight;
            final double height;
            if (onlyOneScreen) {
              height = constraints.maxHeight;
            } else {
              // Reduce [permissionLimitedBarHeight] for the final height.
              height = constraints.maxHeight - permissionLimitedBarHeight;
            }
            // Use [ScrollView.anchor] to determine where is the first place of
            // the [SliverGrid]. Each row needs [dividedSpacing] to calculate,
            // then minus one times of [itemSpacing] because spacing's count in the
            // cross axis is always less than the rows.
            final double anchor = math.min(
              (row * (itemSize + dividedSpacing) + topPadding - itemSpacing) /
                  height,
              1,
            );

            return Directionality(
              textDirection: effectiveGridDirection(context),
              child: ColoredBox(
                color: theme.canvasColor,
                child: Selector<DAPP, List<AssetEntity>>(
                  selector: (_, DAPP p) => p.currentAssets,
                  builder: (_, List<AssetEntity> assets, __) {
                    final SliverGap _bottomGap = SliverGap.v(
                      context.bottomPadding + bottomSectionHeight,
                    );
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: gridScrollController,
                      anchor: effectiveShouldRevertGrid ? anchor : 0,
                      center: effectiveShouldRevertGrid ? gridRevertKey : null,
                      slivers: <Widget>[
                        if (isAppleOS)
                          SliverGap.v(context.topPadding + kToolbarHeight),
                        _sliverGrid(_, assets),
                        // Ignore the gap when the [anchor] is not equal to 1.
                        if (effectiveShouldRevertGrid && anchor == 1)
                          _bottomGap,
                        if (effectiveShouldRevertGrid)
                          SliverToBoxAdapter(
                            key: gridRevertKey,
                            child: const SizedBox.shrink(),
                          ),
                        if (isAppleOS && !effectiveShouldRevertGrid) _bottomGap,
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// There are several conditions within this builder:
  ///  * Return [specialItemBuilder] while the current path is all and
  ///    [specialItemPosition] is not equal to [SpecialItemPosition.none].
  ///  * Return item builder according to the asset's type.
  ///    * [AssetType.audio] -> [audioItemBuilder]
  ///    * [AssetType.image], [AssetType.video] -> [imageAndVideoItemBuilder]
  ///  * Load more assets when the index reached at third line counting
  ///    backwards.
  ///
  /// 资源构建有几个条件：
  ///  * 当前路径是全部资源且 [specialItemPosition] 不等于
  ///    [SpecialItemPosition.none] 时，将会通过 [specialItemBuilder] 构建内容。
  ///  * 根据资源类型返回对应类型的构建：
  ///    * [AssetType.audio] -> [audioItemBuilder] 音频类型
  ///    * [AssetType.image], [AssetType.video] -> [imageAndVideoItemBuilder]
  ///      图片和视频类型
  ///  * 在索引到达倒数第三列的时候加载更多资源。
  @override
  Widget assetGridItemBuilder(
      BuildContext context,
      int index,
      List<AssetEntity> currentAssets,
      ) {
    final DAPP provider = context.watch<DAPP>();
    final AssetPathEntity? currentPathEntity = provider.currentPathEntity;

    int currentIndex;
    switch (specialItemPosition) {
      case SpecialItemPosition.none:
      case SpecialItemPosition.append:
        currentIndex = index;
        break;
      case SpecialItemPosition.prepend:
        currentIndex = index - 1;
        break;
    }

    // Directly return the special item when it's empty.
    if (currentPathEntity == null) {
      if (allowSpecialItemWhenEmpty &&
          specialItemPosition != SpecialItemPosition.none) {
        return specialItemBuilder!(context);
      }
      return const SizedBox.shrink();
    }

    final int _length = currentAssets.length;
    if (currentPathEntity.isAll &&
        specialItemPosition != SpecialItemPosition.none) {
      if ((index == 0 && specialItemPosition == SpecialItemPosition.prepend) ||
          (index == _length &&
              specialItemPosition == SpecialItemPosition.append)) {
        return specialItemBuilder!(context);
      }
    }

    if (!currentPathEntity.isAll) {
      currentIndex = index;
    }

    if (index == _length - gridCount * 3 &&
        context.select<DAPP, bool>(
              (DAPP p) => p.hasMoreToLoad,
        )) {
      provider.loadMoreAssets();
    }

    final AssetEntity asset = currentAssets.elementAt(currentIndex);
    final Widget builder;
    switch (asset.type) {
      case AssetType.audio:
        builder = audioItemBuilder(context, currentIndex, asset);
        break;
      case AssetType.image:
      case AssetType.video:
        builder = imageAndVideoItemBuilder(context, currentIndex, asset);
        break;
      case AssetType.other:
        builder = const SizedBox.shrink();
        break;
    }
    final Widget _content = Stack(
      key: ValueKey<String>(asset.id),
      children: <Widget>[
        builder,
        selectedBackdrop(context, currentIndex, asset),
        if (!isWeChatMoment || asset.type != AssetType.video)
          selectIndicator(context, index, asset),
        itemBannedIndicator(context, asset),
      ],
    );
    return assetGridItemSemanticsBuilder(context, index, asset, _content);
  }

  int semanticIndex(int index) {
    if (specialItemPosition != SpecialItemPosition.prepend) {
      return index + 1;
    }
    return index;
  }

  @override
  Widget assetGridItemSemanticsBuilder(
      BuildContext context,
      int index,
      AssetEntity asset,
      Widget child,
      ) {
    return Consumer2<DAPP, ProviderAggregate>(
      child: child,
      builder: (_, DAPP p, ProviderAggregate pa, Widget? child) {
        final bool isBanned =
            (!p.selectedAssets.contains(asset) && p.selectedMaximumAssets) ||
                (isWeChatMoment &&
                    asset.type == AssetType.video &&
                    p.selectedAssets.isNotEmpty);
        final bool isSelected = p.selectedDescriptions.contains(
          asset.toString(),
        );
        final int selectedIndex = p.selectedAssets.indexOf(asset) + 1;
        String hint = '';
        if (asset.type == AssetType.audio || asset.type == AssetType.video) {
          hint += '${textDelegate.sNameDurationLabel}: ';
          hint += textDelegate.durationIndicatorBuilder(asset.videoDuration);
        }
        if (asset.title?.isNotEmpty == true) {
          hint += ', ${asset.title}';
        }
        return Semantics(
          button: false,
          enabled: !isBanned,
          excludeSemantics: true,
          focusable: pa.isSwitchingPath,
          label: '${textDelegate.semanticTypeLabel(asset.type)}'
              '${semanticIndex(index)}, '
              '${asset.createDateTime.toString().replaceAll('.000', '')}',
          hidden: pa.isSwitchingPath,
          hint: hint,
          image: asset.type == AssetType.image || asset.type == AssetType.video,
          onTap: () => selectAsset(context, asset, isSelected),
          onTapHint: textDelegate.sActionSelectHint,
          onLongPress: isPreviewEnabled
              ? () => _pushAssetToViewer(context, index, asset)
              : null,
          onLongPressHint: textDelegate.sActionPreviewHint,
          selected: isSelected,
          sortKey: OrdinalSortKey(
            semanticIndex(index).toDouble(),
            name: 'GridItem',
          ),
          value: selectedIndex > 0 ? '$selectedIndex' : null,
          child: GestureDetector(
            // Regression https://github.com/flutter/flutter/issues/35112.
            onLongPress:
            isPreviewEnabled && context.mediaQuery.accessibleNavigation
                ? () => _pushAssetToViewer(context, index, asset)
                : null,
            child: IndexedSemantics(index: semanticIndex(index), child: child),
          ),
        );
      },
    );
  }

  @override
  int findChildIndexBuilder({
    required String id,
    required List<AssetEntity> assets,
    int placeholderCount = 0,
  }) {
    int index = assets.indexWhere((AssetEntity e) => e.id == id);
    if (specialItemPosition == SpecialItemPosition.prepend) {
      index += 1;
    }
    index += placeholderCount;
    return index;
  }

  @override
  int assetsGridItemCount({
    required BuildContext context,
    required List<AssetEntity> assets,
    int placeholderCount = 0,
  }) {
    final AssetPathEntity? currentPathEntity =
    context.select<DAPP, AssetPathEntity?>(
          (DAPP p) => p.currentPathEntity,
    );

    if (currentPathEntity == null &&
        specialItemPosition != SpecialItemPosition.none) {
      return 1;
    }

    /// Return actual length if current path is all.
    /// 如果当前目录是全部内容，则返回实际的内容数量。
    final int _length = assets.length + placeholderCount;
    if (!currentPathEntity!.isAll) {
      return _length;
    }
    switch (specialItemPosition) {
      case SpecialItemPosition.none:
        return _length;
      case SpecialItemPosition.prepend:
      case SpecialItemPosition.append:
        return _length + 1;
    }
  }

  @override
  Widget audioIndicator(BuildContext context, AssetEntity asset) {
    final String durationText = textDelegate.durationIndicatorBuilder(
      Duration(seconds: asset.duration),
    );
    return Container(
      width: double.maxFinite,
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.bottomCenter,
          end: AlignmentDirectional.topCenter,
          colors: <Color>[theme.dividerColor, Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: ScaleText(
          durationText,
          semanticsLabel: '${textDelegate.sNameDurationLabel}: '
              '$durationText',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget audioItemBuilder(BuildContext context, int index, AssetEntity asset) {
    return Stack(
      children: <Widget>[
        Container(
          width: double.maxFinite,
          alignment: AlignmentDirectional.topStart,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topCenter,
              end: AlignmentDirectional.bottomCenter,
              colors: <Color>[theme.dividerColor, Colors.transparent],
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, end: 30),
            child: ScaleText(
              asset.title ?? '',
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(0.9, 0.8),
          child: Icon(Icons.audiotrack),
        ),
        audioIndicator(context, asset),
      ],
    );
  }

  /// It'll pop with [AssetPickerProvider.selectedAssets]
  /// when there are any assets were chosen.
  /// 当有资源已选时，点击按钮将把已选资源通过路由返回。
  @override
  Widget confirmButton(BuildContext context) {
    return Consumer<ProviderAggregate>(
      builder: (_, ProviderAggregate pa, __) {
        return MaterialButton(
          minWidth: pa.isSelectedNotEmpty ? 48 : 20,
          height: appBarItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          disabledColor: theme.dividerColor,
          color: pa.isSelectedNotEmpty ? themeColor : theme.dividerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          child: ScaleText(
            pa.isSelectedNotEmpty && !isSingleAssetMode
                ? '${textDelegate.confirm}'
                ' (${pa.selectedAssets.length}/${pa.maxAssets})'
                : textDelegate.confirm,
            style: TextStyle(
              color: pa.isSelectedNotEmpty
                  ? theme.textTheme.bodyText1?.color
                  : theme.textTheme.caption?.color,
              fontSize: 17,
              fontWeight: FontWeight.normal,
            ),
          ),
          onPressed: pa.isSelectedNotEmpty
              ? () => Navigator.of(context).maybePop(pa.selectedAssets)
              : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
    );
  }

  @override
  Widget imageAndVideoItemBuilder(
      BuildContext context,
      int index,
      AssetEntity asset,
      ) {
    final AssetEntityImageProvider imageProvider = AssetEntityImageProvider(
      asset,
      isOriginal: false,
      thumbSize: <int>[gridThumbSize, gridThumbSize],
    );
    SpecialImageType? type;
    if (imageProvider.imageFileType == ImageFileType.gif) {
      type = SpecialImageType.gif;
    } else if (imageProvider.imageFileType == ImageFileType.heic) {
      type = SpecialImageType.heic;
    }
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            child: AssetEntityGridItemBuilder(
              image: imageProvider,
              failedItemBuilder: failedItemBuilder,
            ),
          ),
        ),
        if (type == SpecialImageType.gif) // 如果为GIF则显示标识
          gifIndicator(context, asset),
        if (asset.type == AssetType.video) // 如果为视频则显示标识
          videoIndicator(context, asset),
      ],
    );
  }

  @override
  Widget loadingIndicator(BuildContext context) {
    return Center(
      child: Selector<DAPP, bool>(
        selector: (_, DAPP p) => p.isAssetsEmpty,
        builder: (_, bool isAssetsEmpty, __) {
          if (isAssetsEmpty) {
            return ScaleText(
              textDelegate.emptyList,
              maxScaleFactor: 1.5,
            );
          }
          return PlatformProgressIndicator(
            color: theme.iconTheme.color,
            size: context.mediaQuery.size.width / gridCount / 3,
          );
        },
      ),
    );
  }

  /// While the picker is switching path, this will displayed.
  /// If the user tapped on it, it'll collapse the list widget.
  ///
  /// 当选择器正在选择路径时，它会出现。用户点击它时，列表会折叠收起。
  @override
  Widget pathEntityListBackdrop(BuildContext context) {
    final ProviderAggregate pa = context.watch<ProviderAggregate>();
    return Positioned.fill(
      child: Selector<ProviderAggregate, bool>(
        selector: (_, ProviderAggregate p) => p.isSwitchingPath,
        builder: (_, bool isSwitchingPath, __) => IgnorePointer(
          ignoring: !isSwitchingPath,
          ignoringSemantics: true,
          child: GestureDetector(
            onTap: () => pa.isSwitchingPath = false,
            child: AnimatedOpacity(
              duration: switchingPathDuration,
              opacity: isSwitchingPath ? .75 : 0,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget pathEntityListWidget(BuildContext context) {
    final DAPP provider = context.watch<DAPP>();
    return Positioned.fill(
      top: isAppleOS ? context.topPadding + kToolbarHeight : 0,
      bottom: null,
      child: Consumer<ProviderAggregate>(
        builder: (_, ProviderAggregate p, Widget? child) => Semantics(
          focusable: p.isSwitchingPath,
          sortKey: const OrdinalSortKey(1),
          hidden: !p.isSwitchingPath,
          child: child,
        ),
        child: Selector<ProviderAggregate, bool>(
          selector: (_, ProviderAggregate p) => p.isSwitchingPath,
          builder: (_, bool isSwitchingPath, Widget? w) => AnimatedAlign(
            duration: switchingPathDuration,
            curve: switchingPathCurve,
            alignment: Alignment.bottomCenter,
            heightFactor: isSwitchingPath ? 1 : 0,
            child: AnimatedOpacity(
              duration: switchingPathDuration,
              curve: switchingPathCurve,
              opacity: !isAppleOS || isSwitchingPath ? 1 : 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight:
                    context.mediaQuery.size.height * (isAppleOS ? .6 : .8),
                  ),
                  color: theme.colorScheme.background,
                  child: w,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ValueListenableBuilder<PermissionState>(
                valueListenable: permission,
                builder: (_, PermissionState ps, Widget? child) => Semantics(
                  label: '${textDelegate.viewingLimitedAssetsTip}, '
                      '${textDelegate.changeAccessibleLimitedAssets}',
                  button: true,
                  onTap: PhotoManager.presentLimited,
                  hidden: !isPermissionLimited,
                  focusable: isPermissionLimited,
                  excludeSemantics: true,
                  child: isPermissionLimited ? child : const SizedBox.shrink(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: textDelegate.viewingLimitedAssetsTip,
                        ),
                        TextSpan(
                          text: ' '
                              '${textDelegate.changeAccessibleLimitedAssets}',
                          style:
                          TextStyle(color: interactiveTextColor(context)),
                          recognizer: TapGestureRecognizer()
                            ..onTap = PhotoManager.presentLimited,
                        ),
                      ],
                    ),
                    style: context.themeData.textTheme.caption?.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Selector<DAPP, int>(
                  selector: (_, DAPP p) => p.validPathThumbCount,
                  builder: (_, int count, __) =>
                      Selector<DAPP, Map<AssetPathEntity, Uint8List?>>(
                        selector: (_, DAPP p) => p.pathEntityList,
                        builder: (_, Map<AssetPathEntity, Uint8List?> list, __) {
                          return ListView.separated(
                            padding: const EdgeInsetsDirectional.only(top: 1),
                            shrinkWrap: true,
                            itemCount: list.length,
                            itemBuilder: (BuildContext c, int i) =>
                                pathEntityWidget(
                                  context: c,
                                  list: list,
                                  index: i,
                                  isAudio: (provider as DAPP).requestType ==
                                      RequestType.audio,
                                ),
                            separatorBuilder: (_, __) => Container(
                              margin: const EdgeInsetsDirectional.only(start: 60),
                              height: 1,
                              color: theme.canvasColor,
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget pathEntitySelector(BuildContext context) {
    final DAPP provider = context.watch<DAPP>();
    return UnconstrainedBox(
      child: GestureDetector(
        onTap: () {
          Feedback.forTap(context);
          provider.isSwitchingPath = !provider.isSwitchingPath;
        },
        child: Container(
          height: appBarItemHeight,
          constraints: BoxConstraints(
            maxWidth: context.mediaQuery.size.width * 0.5,
          ),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: theme.dividerColor,
          ),
          child: Selector<DAPP, AssetPathEntity?>(
            selector: (_, DAPP p) => p.currentPathEntity,
            builder: (_, AssetPathEntity? p, Widget? w) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (p != null)
                  Flexible(
                    child: ScaleText(
                      isPermissionLimited && p.isAll
                          ? textDelegate.accessiblePathName
                          : p.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      maxScaleFactor: 1.2,
                    ),
                  ),
                w!,
              ],
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.iconTheme.color!.withOpacity(0.5),
                ),
                child: Selector<ProviderAggregate, bool>(
                  selector: (_, ProviderAggregate p) => p.isSwitchingPath,
                  builder: (_, bool isSwitchingPath, Widget? w) =>
                      Transform.rotate(
                        angle: isSwitchingPath ? math.pi : 0,
                        alignment: Alignment.center,
                        child: w,
                      ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget pathEntityWidget({
    required BuildContext context,
    required Map<AssetPathEntity, Uint8List?> list,
    required int index,
    bool isAudio = false,
  }) {
    final DAPP provider = context.watch<DAPP>();
    final AssetPathEntity pathEntity = list.keys.elementAt(index);
    final Uint8List? data = list.values.elementAt(index);

    Widget builder() {
      if (isAudio) {
        return ColoredBox(
          color: theme.colorScheme.primary.withOpacity(0.12),
          child: const Center(child: Icon(Icons.audiotrack)),
        );
      }

      // The reason that the `thumbData` should be checked at here to see if it
      // is null is that even the image file is not exist, the `File` can still
      // returned as it exist, which will cause the thumb bytes return null.
      //
      // 此处需要检查缩略图为空的原因是：尽管文件可能已经被删除，
      // 但通过 `File` 读取的文件对象仍然存在，使得返回的数据为空。
      if (data != null) {
        return Image.memory(data, fit: BoxFit.cover);
      }
      return ColoredBox(color: theme.colorScheme.primary.withOpacity(0.12));
    }

    final String semanticsName = isPermissionLimited && pathEntity.isAll
        ? textDelegate.accessiblePathName
        : pathEntity.name;
    final String semanticsCount = '${pathEntity.assetCount}';
    return Selector<DAPP, AssetPathEntity?>(
      selector: (_, DAPP p) => p.currentPathEntity,
      builder: (_, AssetPathEntity? currentPathEntity, __) {
        final bool isSelected = currentPathEntity == pathEntity;
        return Semantics(
          label: '$semanticsName, '
              '${textDelegate.sUnitAssetCountLabel}: '
              '$semanticsCount',
          selected: isSelected,
          onTapHint: textDelegate.sActionSwitchPathLabel,
          button: false,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashFactory: InkSplash.splashFactory,
              onTap: () {
                Feedback.forTap(context);
                provider.switchPath(pathEntity);
                gridScrollController.jumpTo(0);
              },
              child: SizedBox(
                height: isAppleOS ? 64 : 52,
                child: Row(
                  children: <Widget>[
                    RepaintBoundary(
                      child: AspectRatio(aspectRatio: 1, child: builder()),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 15,
                          end: 20,
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 10,
                                  ),
                                  child: ScaleText(
                                    semanticsName,
                                    style: const TextStyle(fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              ScaleText(
                                '($semanticsCount)',
                                style: TextStyle(
                                  color: theme.textTheme.caption?.color,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      AspectRatio(
                        aspectRatio: 1,
                        child: Icon(Icons.check, color: themeColor, size: 26),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget previewButton(BuildContext context) {
    final ProviderAggregate pa= context.watch<ProviderAggregate>();

    Future<void> _onTap() async {
      final List<AssetEntity> _selected;
      if (isWeChatMoment) {
        _selected = pa.selectedAssets
            .where((AssetEntity e) => e.type == AssetType.image)
            .toList();
      } else {
        _selected = pa.selectedAssets;
      }
      final List<AssetEntity>? result = await AssetPickerViewer.pushToViewer(
        context,
        currentIndex: 0,
        previewAssets: _selected,
        previewThumbSize: previewThumbSize,
        selectedAssets: _selected,
        selectorProvider: pa as DAPP,
        themeData: theme,
        maxAssets: pa.maxAssets,
      );
      if (result != null) {
        Navigator.of(context).maybePop(result);
      }
    }

    return Consumer2<ProviderAggregate, DAPP>(
      builder: (_, ProviderAggregate pa, DAPP p, Widget? child) => Semantics(
        enabled: pa.isSelectedNotEmpty,
        focusable: pa.isSwitchingPath,
        hidden: pa.isSwitchingPath,
        onTapHint: textDelegate.sActionPreviewHint,
        child: child,
      ),
      child: Selector<ProviderAggregate, bool>(
        selector: (_, ProviderAggregate pa) => pa.isSelectedNotEmpty,
        builder: (_, bool isNotEmpty, __) => GestureDetector(
          onTap: isNotEmpty ? _onTap : null,
          child: Selector<DAPP, String>(
            selector: (_, DAPP p) => p.selectedDescriptions,
            builder: (_, __, ___) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ScaleText(
                '${textDelegate.preview}'
                    '${isNotEmpty ? ' (${pa.selectedAssets.length})' : ''}',
                style: TextStyle(
                  color: isNotEmpty ? null : theme.textTheme.caption?.color,
                  fontSize: 17,
                ),
                maxScaleFactor: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget itemBannedIndicator(BuildContext context, AssetEntity asset) {
    return Consumer<DAPP>(
      builder: (_, DAPP p, __) {
        final bool isDisabled =
            (!p.selectedAssets.contains(asset) && p.selectedMaximumAssets) ||
                (isWeChatMoment &&
                    asset.type == AssetType.video &&
                    p.selectedAssets.isNotEmpty);
        if (isDisabled) {
          return Container(
            color: theme.colorScheme.background.withOpacity(.85),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget selectIndicator(BuildContext context, int index, AssetEntity asset) {
    final Duration duration = switchingPathDuration * 0.75;
    return Selector<DAPP, String>(
      selector: (_, DAPP p) => p.selectedDescriptions,
      builder: (BuildContext context, String descriptions, __) {
        final bool selected = descriptions.contains(asset.toString());
        final double indicatorSize =
            context.mediaQuery.size.width / gridCount / 3;
        final Widget innerSelector = AnimatedContainer(
          duration: duration,
          width: indicatorSize / (isAppleOS ? 1.25 : 1.5),
          height: indicatorSize / (isAppleOS ? 1.25 : 1.5),
          decoration: BoxDecoration(
            border:
            !selected ? Border.all(color: Colors.white, width: 2) : null,
            color: selected ? themeColor : null,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: duration,
            reverseDuration: duration,
            child: selected
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
        );
        final Widget selectorWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => selectAsset(context, asset, selected),
          child: Container(
            margin: EdgeInsets.all(
              context.mediaQuery.size.width / gridCount / 12,
            ),
            width: isPreviewEnabled ? indicatorSize : null,
            height: isPreviewEnabled ? indicatorSize : null,
            alignment: AlignmentDirectional.topEnd,
            child: (!isPreviewEnabled && isSingleAssetMode && !selected)
                ? const SizedBox.shrink()
                : innerSelector,
          ),
        );
        if (isPreviewEnabled) {
          return PositionedDirectional(
            top: 0,
            end: 0,
            child: selectorWidget,
          );
        }
        return selectorWidget;
      },
    );
  }

  @override
  Widget selectedBackdrop(BuildContext context, int index, AssetEntity asset) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: isPreviewEnabled
            ? () => _pushAssetToViewer(context, index, asset)
            : null,
        child: Consumer<DAPP>(
          builder: (_, DAPP p, __) {
            final int index = p.selectedAssets.indexOf(asset);
            final bool selected = index != -1;
            return AnimatedContainer(
              duration: switchingPathDuration,
              color: selected
                  ? theme.colorScheme.primary.withOpacity(.45)
                  : Colors.black.withOpacity(.1),
              child: selected && !isSingleAssetMode
                  ? Container(
                alignment: AlignmentDirectional.topStart,
                padding: const EdgeInsets.all(14),
                child: ScaleText(
                  '${index + 1}',
                  style: TextStyle(
                    color: theme.textTheme.bodyText1?.color
                        ?.withOpacity(.75),
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                  maxScaleFactor: 1.4,
                ),
              )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  /// Videos often contains various of color in the cover,
  /// so in order to keep the content visible in most cases,
  /// the color of the indicator has been set to [Colors.white].
  ///
  /// 视频封面通常包含各种颜色，为了保证内容在一般情况下可见，此处
  /// 将指示器的图标和文字设置为 [Colors.white]。
  @override
  Widget videoIndicator(BuildContext context, AssetEntity asset) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: 0,
      child: Container(
        width: double.maxFinite,
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.bottomCenter,
            end: AlignmentDirectional.topCenter,
            colors: <Color>[theme.dividerColor, Colors.transparent],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.videocam, size: 22, color: Colors.white),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: ScaleText(
                  textDelegate.durationIndicatorBuilder(
                    Duration(seconds: asset.duration),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  strutStyle: const StrutStyle(
                    forceStrutHeight: true,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  maxScaleFactor: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
