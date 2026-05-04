/**
 * 閫氱敤 LazyForEach 鏁版嵁婧愰€傞厤鍣?
 * 灏嗘櫘閫氭暟缁勮浆鎹负 IDataDataSource 鎺ュ彛
 * 鐢ㄤ簬浼樺寲澶ф暟鎹垪琛ㄧ殑娓叉煋鎬ц兘
 *
 * @since 6.0.0
 */

/**
 * 鏁版嵁鍙樺寲鐩戝惉鍣ㄦ帴鍙ｏ紙鏇夸唬 @kit.ArkUI 涓殑瀵煎嚭锛?
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
 * 鏁版嵁婧愭帴鍙ｏ紙鏇夸唬 @kit.ArkUI 涓殑瀵煎嚭锛?
 */
interface IDataSource {
  totalCount(): number;
  getData(index: number): Object;
  registerDataChangeListener(listener: DataChangeListener): void;
  unregisterDataChangeListener(listener: DataChangeListener): void;
}

/**
 * 閫氱敤 LazyForEach 鏁版嵁婧?
 * 鏀寔浠绘剰绫诲瀷鐨勬暟缁勬暟鎹?
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
   * 璁剧疆鏁版嵁
   * @param data 鏂版暟鎹暟缁?
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
   * 杩藉姞鏁版嵁
   * @param items 瑕佽拷鍔犵殑鏁版嵁椤?
   */
  appendData(items: T[]): void {
    for (let i = 0; i < items.length; i++) {
      this.dataArray.push(items[i]);
      this.dataKeys.push(this.idGenerator(items[i], this.dataArray.length - 1));
    }
    this.notifyDataAdd();
  }

  /**
   * 鏇存柊鍗曚釜鏁版嵁椤?
   * @param index 鏁版嵁绱㈠紩
   * @param item 鏂版暟鎹」
   */
  updateData(index: number, item: T): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray[index] = item;
      this.dataKeys[index] = this.idGenerator(item, index);
      this.notifyDataChange(index);
    }
  }

  /**
   * 鍒犻櫎鍗曚釜鏁版嵁椤?
   * @param index 鏁版嵁绱㈠紩
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
   * 娓呯┖鎵€鏈夋暟鎹?
   */
  clear(): void {
    this.dataArray = [];
    this.dataKeys = [];
    this.notifyDataReload();
  }

  /**
   * 鑾峰彇鏁版嵁鎬绘暟
   */
  totalCount(): number {
    return this.dataArray.length;
  }

  /**
   * 鑾峰彇鎸囧畾浣嶇疆鐨勬暟鎹」
   */
  getData(index: number): T {
    return this.dataArray[index];
  }

  /**
   * 娉ㄥ唽鏁版嵁鍙樺寲鐩戝惉
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  /**
   * 娉ㄩ攢鏁版嵁鍙樺寲鐩戝惉
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
