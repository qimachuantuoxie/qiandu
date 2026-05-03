/**
 * 通用 LazyForEach 数据源适配器
 * 将普通数组转换为 IDataDataSource 接口
 * 用于优化大数据列表的渲染性能
 *
 * @since 6.0.0
 */

/**
 * 数据变化监听器接口（替代 @kit.ArkUI 中的导出）
 */
interface DataChangeListener {
  onDataReloaded(): void;
  onDataAdded(index: number): void;
  onDataMoved(from: number, to: number): void;
  onDataDeleted(index: number): void;
  onDataChanged(index: number): void;
  onDataAdd(index: number): void;
  onDataMove(from: number, to: number): void;
  onDataDelete(index: number): void;
  onDataChange(index: number): void;
}

/**
 * 数据源接口（替代 @kit.ArkUI 中的导出）
 */
interface IDataSource {
  totalCount(): number;
  getData(index: number): Object;
  registerDataChangeListener(listener: DataChangeListener): void;
  unregisterDataChangeListener(listener: DataChangeListener): void;
}

/**
 * 通用 LazyForEach 数据源
 * 支持任意类型的数组数据
 */
export class LazyDataSource<T extends Object> implements IDataSource {
  private dataArray: T[] = [];
  private dataKeys: string[] = [];
  private listeners: DataChangeListener[] = [];
  private idGenerator: (item: T, index: number) => string;

  constructor(idGenerator: (item: T, index: number) => string) {
    this.idGenerator = idGenerator;
  }

  /**
   * 设置数据
   * @param data 新数据数组
   */
  setData(data: T[]): void {
    this.dataArray = data;
    this.dataKeys = [];
    for (let i = 0; i < data.length; i++) {
      this.dataKeys.push(this.idGenerator(data[i], i));
    }
    this.notifyDataReload();
  }

  /**
   * 追加数据
   * @param items 要追加的数据项
   */
  appendData(items: T[]): void {
    for (let i = 0; i < items.length; i++) {
      this.dataArray.push(items[i]);
      this.dataKeys.push(this.idGenerator(items[i], this.dataArray.length - 1));
    }
    this.notifyDataAdd();
  }

  /**
   * 更新单个数据项
   * @param index 数据索引
   * @param item 新数据项
   */
  updateData(index: number, item: T): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray[index] = item;
      this.dataKeys[index] = this.idGenerator(item, index);
      this.notifyDataChange(index);
    }
  }

  /**
   * 删除单个数据项
   * @param index 数据索引
   */
  removeData(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      const newData: T[] = [];
      for (let i = 0; i < this.dataArray.length; i++) {
        if (i !== index) {
          newData.push(this.dataArray[i]);
        }
      }
      this.dataArray = newData;
      this.dataKeys = [];
      for (let i = 0; i < newData.length; i++) {
        this.dataKeys.push(this.idGenerator(newData[i], i));
      }
      this.notifyDataDelete(index);
    }
  }

  /**
   * 清空所有数据
   */
  clear(): void {
    this.dataArray = [];
    this.dataKeys = [];
    this.notifyDataReload();
  }

  /**
   * 获取数据总数
   */
  totalCount(): number {
    return this.dataArray.length;
  }

  /**
   * 获取指定位置的数据项
   */
  getData(index: number): T {
    return this.dataArray[index];
  }

  /**
   * 注册数据变化监听
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  /**
   * 注销数据变化监听
   */
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyDataReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }

  private notifyDataAdd(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataAdded(this.dataArray.length - 1);
    }
  }

  private notifyDataDelete(index: number): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataDeleted(index);
    }
  }

  private notifyDataChange(index: number): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataChanged(index);
    }
  }
}
