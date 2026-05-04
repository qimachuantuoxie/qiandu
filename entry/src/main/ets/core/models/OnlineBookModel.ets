/**
 * 閸︺劎鍤庢稊锔剧潉娣団剝浼呭Ο鈥崇€?
 * 閹碘晛鐫?BookInfo 閺€顖涘瘮缂冩垹绮舵稊锔剧潉
 * 
 * @since 2.8.0
 */

import { BookInfo, BookFormat, ReadStatus } from './BookModel';

/**
 * 閸︺劎鍤庨幖婊呭偍缂佹挻鐏?
 */
export interface OnlineSearchResult {
  /** 娑旓妇鐫勯崥宥囆?*/
  bookName: string;
  /** 娴ｆ粏鈧?*/
  author: string;
  /** 鐏忎線娼癠RL */
  coverUrl: string;
  /** 娑旓妇鐫勭拠锔藉剰妞ょぅRL */
  bookUrl: string;
  /** 娑旓附绨甀D */
  sourceId: string;
  /** 娑旓附绨崥宥囆?*/
  sourceName: string;
  /** 閺堚偓閺傛壆鐝烽懞?*/
  latestChapter: string;
  /** 缁犫偓娴?*/
  intro: string;
  /** 鐎涙鏆?*/
  wordCount: number;
  /** 閺囧瓨鏌婇弮鍫曟？ */
  updateTime: string;
}

/**
 * 閸︺劎鍤庢稊锔剧潉鐠囷附鍎?
 */
export interface OnlineBookDetail {
  /** 娑旓妇鐫勯崥宥囆?*/
  title: string;
  /** 娴ｆ粏鈧?*/
  author: string;
  /** 鐏忎線娼癠RL */
  coverUrl: string;
  /** 娑旓妇鐫勭拠锔藉剰妞ょぅRL */
  bookUrl: string;
  /** 娑旓附绨甀D */
  sourceId: string;
  /** 缁犫偓娴?*/
  intro: string;
  /** 閺堚偓閺傛壆鐝烽懞?*/
  latestChapter: string;
  /** 鐎涙鏆?*/
  wordCount: number;
  /** 閺囧瓨鏌婇弮鍫曟？ */
  updateTime: string;
  /** 閸掑棛琚?*/
  category: string;
  /** 閻樿埖鈧緤绱欐潻鐐舵祰/鐎瑰瞼绮ㄩ敍?*/
  status: string;
  /** 閻╊喖缍?*/
  toc?: OnlineChapterInfo[];
}

/**
 * 閸︺劎鍤庣粩鐘哄Ν娣団剝浼?
 */
export interface OnlineChapterInfo {
  /** 缁旂姾濡槐銏犵穿 */
  index: number;
  /** 缁旂姾濡弽鍥暯 */
  title: string;
  /** 缁旂姾濡璘RL */
  url: string;
  /** 閺勵垰鎯乂IP */
  isVip: boolean;
  /** 鐎涙鏆?*/
  wordCount: number;
  /** 閺囧瓨鏌婇弮鍫曟？ */
  updateTime: string;
  /** 閸愬懎顔愰敍鍫濆鏉炶棄鎮楅敍?*/
  content?: string;
}

/**
 * 閸︺劎鍤庢稊锔剧潉缂傛挸鐡?
 */
export interface OnlineBookCache {
  /** 娑旓妇鐫勭拠锔藉剰 */
  detail: OnlineBookDetail;
  /** 閻╊喖缍?*/
  toc: OnlineChapterInfo[];
  /** 瀹歌尙绱︾€涙娈戠粩鐘哄Ν閸愬懎顔?*/
  cachedChapters: Map<number, string>;
  /** 缂傛挸鐡ㄩ弮鍫曟？ */
  cacheTime: number;
}

/**
 * 閸︺劎鍤庢稊锔剧潉娣団剝浼呴敍鍫熷⒖鐏?BookInfo閿?
 */
export interface OnlineBookInfo {
  /** 娑旓妇鐫勯崬顖欑閺嶅洩鐦?*/
  id: string;
  /** 娑旓箑鎮?*/
  title: string;
  /** 娴ｆ粏鈧?*/
  author: string;
  /** 閺傚洣娆㈢捄顖氱窞閿涘牆婀痪澶稿姛缁秳璐熺粚鐚寸礆 */
  filePath: string;
  /** 鐏忎線娼扮捄顖氱窞 */
  coverPath: string;
  /** 娑旓妇鐫勯弽鐓庣础 */
  format: BookFormat;
  /** 閹銆夐弫?*/
  totalPages: number;
  /** 瑜版挸澧犳い?*/
  currentPage: number;
  /** 闂冨懓顕版潻娑樺 */
  readProgress: number;
  /** 閺堚偓閸氬酣妲勭拠缁樻闂?*/
  lastReadTime: number;
  /** 濞ｈ濮為弮鍫曟？ */
  addTime: number;
  /** 闂冨懓顕伴悩鑸碘偓?*/
  status: ReadStatus;
  /** 閺勵垰鎯侀弨鎯版 */
  isFavorite: boolean;
  /** 閹碘偓鐏炵偛鍨庣紒?*/
  groupIds: string[];
  /** 閹妲勭拠缁樻闂€?*/
  totalReadTime: number;
  /** 閺傚洣娆㈡径褍鐨?*/
  fileSize: number;
  /** 娑旓妇鐫勭拠锔藉剰妞ょぅRL */
  bookUrl: string;
  /** 娑旓附绨甀D */
  sourceId: string;
  /** 娑旓附绨崥宥囆?*/
  sourceName: string;
  /** 閺勵垰鎯佹稉鍝勬躬缁惧じ鍔熺猾?*/
  isOnline: boolean;
  /** 缁犫偓娴?*/
  intro: string;
  /** 閺堚偓閺傛壆鐝烽懞?*/
  latestChapter: string;
  /** 娑旓妇鐫勯幓蹇氬牚閿涘牆褰查柅澶涚礆 */
  description?: string;
  /** 閺嶅洨顒烽敍鍫濆讲闁绱?*/
  tags?: string[];
}

/**
 * 鐏忓棗婀痪鎸庢偝缁便垻绮ㄩ弸婊嗘祮閹诡澀璐?OnlineBookInfo
 */
export function convertOnlineSearchToBookInfo(
  searchResult: OnlineSearchResult
): OnlineBookInfo {
  const bookInfo: OnlineBookInfo = {
    id: `online_${searchResult.sourceId}_${Date.now()}`,
    title: searchResult.bookName,
    author: searchResult.author,
    filePath: '',
    coverPath: searchResult.coverUrl,
    format: BookFormat.TXT,
    totalPages: 0,
    currentPage: 0,
    readProgress: 0,
    lastReadTime: 0,
    addTime: Date.now(),
    status: ReadStatus.UNREAD,
    isFavorite: false,
    groupIds: [],
    totalReadTime: 0,
    fileSize: 0,
    bookUrl: searchResult.bookUrl,
    sourceId: searchResult.sourceId,
    sourceName: searchResult.sourceName,
    isOnline: true,
    intro: searchResult.intro,
    latestChapter: searchResult.latestChapter
  };
  return bookInfo;
}
