# ContactManager

目前只有读取功能



### 主要功能：

* 读取详细信息

### 主要接口

```
class func allRecord()->[Record]

class func record(#name: String) -> [Record]

class func record(#count: Int, loadedCount: Int, lastRecord: Record?) -> [Record]

class func record(#recordId: String) -> Record?

class func recordCount() -> Int
```


