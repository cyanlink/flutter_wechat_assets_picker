# 针对原来wechat_asset_picker进行的改动
1. 进行MVVM抽象重构，做到关注点分离。
2. UI，View层，要抛弃delegate模式，允许完全自行编写拼接UI布局。靠上层Provider注入VM。
3. 抽离出ViewModel，包括加载分页逻辑，路径切换等。
4. 写一个完全只负责数据加载的Model类。
5. 修改本库的定位，让他能完美服务于单纯的拿来进行代码复用拼接的目的。

# 结论笔记
## UI层
1. delegate被取消，现在应当由扩展者提供页面Widget，由库进行依赖注入；而不是传入delegate。
2. 正因如此，页面内部（原来的delegate）不再应当通过参数传入并持有provider，而应该直接通过context获取，因为它拥有了自己的context。
3. 原来的DefaultDelegate中的实现，均应该变为Mixin。

## VM层
1. 目前的想法是，并没有一个真正意义上的所谓的Model层，一切逻辑都是靠VM保持状态、进行加载操作等。
2. 如何实现单加载、多筛选功能：靠一个ProviderVM向下面多个Consumer注入不同的视图来做到。需要继续看provider管理源码。

1. 可能需要将DAPP轻量化，不要让他直接负责加载，而只是一个筛选器。
2. 如何改变UI看到的数据"视图"？