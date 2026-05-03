import { i18n } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { userPrefs } from './prefs';

export type LocaleCode = 'zh_CN' | 'en_US' | 'ja_JP' | 'ko_KR' | 'fr_FR' | 'es_ES' | 'de_DE' | 'pt_BR' | 'ru_RU' | 'ar_SA';

export interface LocaleInfo {
  code: LocaleCode;
  name: string;
  nativeName: string;
  direction: 'ltr' | 'rtl';
}

export const SUPPORTED_LOCALES: LocaleInfo[] = [
  { code: 'zh_CN', name: 'Chinese (Simplified)', nativeName: '简体中文', direction: 'ltr' },
  { code: 'en_US', name: 'English', nativeName: 'English', direction: 'ltr' },
  { code: 'ja_JP', name: 'Japanese', nativeName: '日本語', direction: 'ltr' },
  { code: 'ko_KR', name: 'Korean', nativeName: '한국어', direction: 'ltr' },
  { code: 'fr_FR', name: 'French', nativeName: 'Français', direction: 'ltr' },
  { code: 'es_ES', name: 'Spanish', nativeName: 'Español', direction: 'ltr' },
  { code: 'de_DE', name: 'German', nativeName: 'Deutsch', direction: 'ltr' },
  { code: 'pt_BR', name: 'Portuguese', nativeName: 'Português', direction: 'ltr' },
  { code: 'ru_RU', name: 'Russian', nativeName: 'Русский', direction: 'ltr' },
  { code: 'ar_SA', name: 'Arabic', nativeName: 'العربية', direction: 'rtl' }
];

// Map for locale conversion
const LOCALE_MAP = new Map<string, LocaleCode>([
  ['zh-Hans', 'zh_CN'], ['zh-CN', 'zh_CN'], ['zh', 'zh_CN'],
  ['en-US', 'en_US'], ['en-GB', 'en_US'], ['en', 'en_US'],
  ['ja', 'ja_JP'], ['ja-JP', 'ja_JP'],
  ['ko', 'ko_KR'], ['ko-KR', 'ko_KR'],
  ['fr', 'fr_FR'], ['fr-FR', 'fr_FR'],
  ['es', 'es_ES'], ['es-ES', 'es_ES'],
  ['de', 'de_DE'], ['de-DE', 'de_DE'],
  ['pt', 'pt_BR'], ['pt-BR', 'pt_BR'],
  ['ru', 'ru_RU'], ['ru-RU', 'ru_RU'],
  ['ar', 'ar_SA'], ['ar-SA', 'ar_SA']
]);

// Translation interface for each locale
interface TranslationMap {
  app_name: string;
  app_slogan: string;
  loading: string;
  welcome: string;
  login: string;
  bookshelf: string;
  search: string;
  settings: string;
  about: string;
  import_books: string;
  import: string;
  empty_shelf: string;
  book_format: string;
  author: string;
  unknown_author: string;
  reading_progress: string;
  read_settings: string;
  display_settings: string;
  font_settings: string;
  font: string;
  font_size: string;
  letter_spacing: string;
  line_spacing: string;
  paragraph_spacing: string;
  text_indent: string;
  page_turn_settings: string;
  page_mode: string;
  volume_key_turn: string;
  click_turn: string;
  reading_theme: string;
  text_convert: string;
  chinese_convert: string;
  tts_settings: string;
  tts_speed: string;
  tts_pitch: string;
  close: string;
  cancel: string;
  confirm: string;
  done: string;
  save: string;
  system_default: string;
  theme_light: string;
  theme_sepia: string;
  theme_dark: string;
  theme_auto: string;
  scroll: string;
  cover: string;
  simulation: string;
  slide: string;
  none: string;
  off: string;
  to_traditional: string;
  to_simplified: string;
  screen_settings: string;
  auto_brightness: string;
  keep_screen_on: string;
  full_screen: string;
  show_status_bar: string;
  cache_settings: string;
  cache_size: string;
  clear_cache: string;
  statistics: string;
  local_books: string;
  version: string;
  copyright: string;
  reader: string;
  page_of: string;
  slide_to_read: string;
  next_page: string;
  prev_page: string;
  table_of_contents: string;
  bookmarks: string;
  notes: string;
  highlight: string;
  add_bookmark: string;
  remove_bookmark: string;
  ocr_scan: string;
  ocr_scan_hint: string;
  recognizing: string;
  recognition_failed: string;
  recognition_success: string;
  copy_text: string;
  insert_to_book: string;
  file_picker: string;
  import_success: string;
  import_failed: string;
  reading_stats: string;
  total_books: string;
  finished_books: string;
  reading_days: string;
  total_time: string;
  today: string;
  this_week: string;
  total: string;
  hours: string;
  minutes: string;
  books_count: string;
  days_count: string;
  achievements: string;
  no_achievements: string;
  features_showcase: string;
  core_features: string;
  pure_reading: string;
  advanced_notes: string;
  tts_feature: string;
  harmony_cards: string;
  ebook_formats: string;
  format_support: string;
  pdf: string;
  epub: string;
  mobi: string;
  txt: string;
  docx: string;
  cbz: string;
  cbr: string;
  read_now: string;
  view_details: string;
  retry: string;
  error: string;
  success: string;
  warning: string;
  info: string;
  yes: string;
  no: string;
  ok: string;
  back: string;
  close_hint: string;
  no_more: string;
  load_more: string;
  refreshing: string;
  no_data: string;
  no_result: string;
  processing: string;
  computing: string;
  permission_denied: string;
  permission_required: string;
  grant: string;
  denied: string;
  network_error: string;
  file_not_support: string;
  search_hint: string;
  reading: string;
  favorite: string;
  finished: string;
  all: string;
  privacy_policy: string;
  user_agreement: string;
  login_account: string;
  guest_mode: string;
  login_your_account: string;
  i_agree: string;
  donation: string;
  feedback: string;
  loading_resources: string;
  init_engine: string;
  prepare_reading: string;
  help_docs: string;
  legal_support: string;
  donate: string;
  select_language: string;
  current_language: string;
  language_settings: string;
}

// Translations type instead of Record
interface TranslationsMap {
  zh_CN: TranslationMap;
  en_US: TranslationMap;
  ja_JP: TranslationMap;
  ko_KR: TranslationMap;
  fr_FR: TranslationMap;
  es_ES: TranslationMap;
  de_DE: TranslationMap;
  pt_BR: TranslationMap;
  ru_RU: TranslationMap;
  ar_SA: TranslationMap;
}

// Define translation objects with explicit type
const zhCNTranslations: TranslationMap = {
  app_name: '千读阅界', app_slogan: '阅尽千卷 · 视界无限', loading: '加载中...',
  welcome: '欢迎使用', login: '登录', bookshelf: '书架', search: '搜索',
  settings: '设置', about: '关于', import_books: '导入书籍', import: '导入',
  empty_shelf: '书架空空如也', book_format: '书籍格式', author: '作者',
  unknown_author: '未知作者', reading_progress: '阅读进度', read_settings: '阅读设置',
  display_settings: '显示设置', font_settings: '字体设置', font: '字体',
  font_size: '字体大小', letter_spacing: '字间距', line_spacing: '行间距',
  paragraph_spacing: '段间距', text_indent: '首行缩进', page_turn_settings: '翻页设置',
  page_mode: '翻页模式', volume_key_turn: '音量键翻页', click_turn: '点击翻页',
  reading_theme: '阅读主题', text_convert: '文字转换', chinese_convert: '简繁转换',
  tts_settings: '语音朗读', tts_speed: '朗读速度', tts_pitch: '音调',
  close: '关闭', cancel: '取消', confirm: '确认', done: '完成', save: '保存',
  system_default: '系统默认', theme_light: '白天', theme_sepia: '护眼',
  theme_dark: '夜间', theme_auto: '自动', scroll: '滚动', cover: '覆盖',
  simulation: '仿真', slide: '滑动', none: '无动画', off: '关闭',
  to_traditional: '简转繁', to_simplified: '繁转简', screen_settings: '屏幕设置',
  auto_brightness: '自动亮度', keep_screen_on: '保持屏幕常亮', full_screen: '全屏模式',
  show_status_bar: '显示状态栏', cache_settings: '缓存管理', cache_size: '缓存大小',
  clear_cache: '清除缓存', statistics: '统计', local_books: '本地书籍',
  version: '版本', copyright: '版权', reader: '阅读器', page_of: '/',
  slide_to_read: '下滑翻页阅读', next_page: '下一页', prev_page: '上一页',
  table_of_contents: '目录', bookmarks: '书签', notes: '笔记', highlight: '高亮',
  add_bookmark: '添加书签', remove_bookmark: '移除书签', ocr_scan: 'OCR扫描',
  ocr_scan_hint: '扫描识别文字', recognizing: '识别中...', recognition_failed: '识别失败',
  recognition_success: '识别成功', copy_text: '复制文字', insert_to_book: '插入到书籍',
  file_picker: '文件选择', import_success: '导入成功', import_failed: '导入失败',
  reading_stats: '阅读统计', total_books: '总书籍', finished_books: '已读完',
  reading_days: '阅读天数', total_time: '总时长', today: '今日', this_week: '本周',
  total: '总计', hours: '小时', minutes: '分钟', books_count: '本', days_count: '天',
  achievements: '成就徽章', no_achievements: '还没有获得徽章，继续阅读吧！',
  features_showcase: '功能展示', core_features: '核心功能', pure_reading: '纯净阅读体验',
  advanced_notes: '高级笔记系统', tts_feature: 'TTS听书功能', harmony_cards: '鸿蒙服务卡片',
  ebook_formats: '电子书全格式', format_support: '7种格式支持', pdf: 'PDF', epub: 'EPUB',
  mobi: 'MOBI', txt: 'TXT', docx: 'DOCX', cbz: 'CBZ', cbr: 'CBR',
  read_now: '立即阅读', view_details: '查看详情', retry: '重试', error: '错误',
  success: '成功', warning: '警告', info: '提示', yes: '是', no: '否', ok: '确定',
  back: '返回', close_hint: '点击任意位置关闭', no_more: '没有更多了',
  load_more: '上拉加载更多', refreshing: '刷新中...', no_data: '暂无数据',
  no_result: '无搜索结果', processing: '处理中...', computing: '计算中...',
  permission_denied: '权限被拒绝', permission_required: '需要权限', grant: '授予',
  denied: '拒绝', network_error: '网络错误', file_not_support: '不支持的文件格式',
  search_hint: '搜索书籍...', reading: '阅读中', favorite: '收藏', finished: '已完成',
  all: '全部', privacy_policy: '隐私政策', user_agreement: '用户协议',
  login_account: '账号登录', guest_mode: '游客模式', login_your_account: '登录您的账号',
  i_agree: '我已阅读并同意', donation: '打赏支持', feedback: '意见反馈',
  loading_resources: '加载资源...', init_engine: '初始化引擎...', prepare_reading: '准备阅读体验...',
  help_docs: '帮助文档', legal_support: '法律与支持', donate: '捐赠',
  select_language: '选择语言', current_language: '当前语言', language_settings: '语言设置'
};

const enUSTranslations: TranslationMap = {
  app_name: 'QianDu Reader', app_slogan: 'Read Limitless', loading: 'Loading...',
  welcome: 'Welcome', login: 'Login', bookshelf: 'Bookshelf', search: 'Search',
  settings: 'Settings', about: 'About', import_books: 'Import Books', import: 'Import',
  empty_shelf: 'Your bookshelf is empty', book_format: 'Book Format', author: 'Author',
  unknown_author: 'Unknown Author', reading_progress: 'Reading Progress', read_settings: 'Reading Settings',
  display_settings: 'Display Settings', font_settings: 'Font Settings', font: 'Font',
  font_size: 'Font Size', letter_spacing: 'Letter Spacing', line_spacing: 'Line Spacing',
  paragraph_spacing: 'Paragraph Spacing', text_indent: 'Text Indent', page_turn_settings: 'Page Turn Settings',
  page_mode: 'Page Mode', volume_key_turn: 'Volume Key Turn', click_turn: 'Click to Turn',
  reading_theme: 'Reading Theme', text_convert: 'Text Conversion', chinese_convert: 'Chinese Conversion',
  tts_settings: 'TTS Settings', tts_speed: 'TTS Speed', tts_pitch: 'TTS Pitch',
  close: 'Close', cancel: 'Cancel', confirm: 'Confirm', done: 'Done', save: 'Save',
  system_default: 'System Default', theme_light: 'Light', theme_sepia: 'Sepia',
  theme_dark: 'Dark', theme_auto: 'Auto', scroll: 'Scroll', cover: 'Cover',
  simulation: 'Simulation', slide: 'Slide', none: 'None', off: 'Off',
  to_traditional: 'To Traditional', to_simplified: 'To Simplified', screen_settings: 'Screen Settings',
  auto_brightness: 'Auto Brightness', keep_screen_on: 'Keep Screen On', full_screen: 'Full Screen',
  show_status_bar: 'Show Status Bar', cache_settings: 'Cache Settings', cache_size: 'Cache Size',
  clear_cache: 'Clear Cache', statistics: 'Statistics', local_books: 'Local Books',
  version: 'Version', copyright: 'Copyright', reader: 'Reader', page_of: '/',
  slide_to_read: 'Slide down to read', next_page: 'Next Page', prev_page: 'Previous Page',
  table_of_contents: 'Contents', bookmarks: 'Bookmarks', notes: 'Notes', highlight: 'Highlight',
  add_bookmark: 'Add Bookmark', remove_bookmark: 'Remove Bookmark', ocr_scan: 'OCR Scan',
  ocr_scan_hint: 'Scan to recognize text', recognizing: 'Recognizing...', recognition_failed: 'Recognition Failed',
  recognition_success: 'Recognition Success', copy_text: 'Copy Text', insert_to_book: 'Insert to Book',
  file_picker: 'File Picker', import_success: 'Import Success', import_failed: 'Import Failed',
  reading_stats: 'Reading Stats', total_books: 'Total Books', finished_books: 'Finished',
  reading_days: 'Reading Days', total_time: 'Total Time', today: 'Today', this_week: 'This Week',
  total: 'Total', hours: 'Hours', minutes: 'Minutes', books_count: 'Books', days_count: 'Days',
  achievements: 'Achievements', no_achievements: 'No achievements yet, keep reading!',
  features_showcase: 'Features', core_features: 'Core Features', pure_reading: 'Pure Reading Experience',
  advanced_notes: 'Advanced Notes', tts_feature: 'TTS Feature', harmony_cards: 'HarmonyOS Cards',
  ebook_formats: 'E-book Formats', format_support: '7 Formats Support', pdf: 'PDF', epub: 'EPUB',
  mobi: 'MOBI', txt: 'TXT', docx: 'DOCX', cbz: 'CBZ', cbr: 'CBR',
  read_now: 'Read Now', view_details: 'View Details', retry: 'Retry', error: 'Error',
  success: 'Success', warning: 'Warning', info: 'Info', yes: 'Yes', no: 'No', ok: 'OK',
  back: 'Back', close_hint: 'Tap anywhere to close', no_more: 'No more',
  load_more: 'Pull to load more', refreshing: 'Refreshing...', no_data: 'No Data',
  no_result: 'No Results', processing: 'Processing...', computing: 'Computing...',
  permission_denied: 'Permission Denied', permission_required: 'Permission Required', grant: 'Grant',
  denied: 'Denied', network_error: 'Network Error', file_not_support: 'File Format Not Supported',
  search_hint: 'Search books...', reading: 'Reading', favorite: 'Favorite', finished: 'Finished',
  all: 'All', privacy_policy: 'Privacy Policy', user_agreement: 'User Agreement',
  login_account: 'Account Login', guest_mode: 'Guest Mode', login_your_account: 'Login to your account',
  i_agree: 'I have read and agree', donation: 'Donation', feedback: 'Feedback',
  loading_resources: 'Loading resources...', init_engine: 'Initializing engine...', prepare_reading: 'Preparing reading experience...',
  help_docs: 'Help Docs', legal_support: 'Legal & Support', donate: 'Donate',
  select_language: 'Select Language', current_language: 'Current Language', language_settings: 'Language Settings'
};

// Translation storage - use specific locale keys instead of indexed access
const TRANSLATIONS: TranslationsMap = {
  zh_CN: zhCNTranslations,
  en_US: enUSTranslations,
  ja_JP: {} as TranslationMap, // Add Japanese translations as needed
  ko_KR: {} as TranslationMap, // Add Korean translations as needed
  fr_FR: {} as TranslationMap, // Add French translations as needed
  es_ES: {} as TranslationMap, // Add Spanish translations as needed
  de_DE: {} as TranslationMap, // Add German translations as needed
  pt_BR: {} as TranslationMap, // Add Portuguese translations as needed
  ru_RU: {} as TranslationMap, // Add Russian translations as needed
  ar_SA: {} as TranslationMap // Add Arabic translations as needed
};

// I18nManager class
class I18nManager {
  private static instance: I18nManager;
  private currentLocale: LocaleCode = 'en_US';
  private context: common.Context | null = null;
  private pref: preferences.Preferences | null = null;
  private readonly PREF_NAME = 'i18n_prefs';
  private readonly KEY_LOCALE = 'locale';

  private constructor() {}

  static getInstance(): I18nManager {
    if (!I18nManager.instance) {
      I18nManager.instance = new I18nManager();
    }
    return I18nManager.instance;
  }

  getSystemLocale(): LocaleCode {
    try {
      const systemLocale: string = i18n.System.getSystemLanguage();
      const localeCode = this.convertLocale(systemLocale);
      return localeCode || 'en_US';
    } catch {
      return 'en_US';
    }
  }

  private convertLocale(systemLocale: string): LocaleCode | null {
    // Check full locale first
    const fullLocale = systemLocale.replace('-', '_');
    if (this.isValidLocale(fullLocale)) {
      return fullLocale as LocaleCode;
    }
    // Check prefix
    const parts = systemLocale.split('-');
    if (parts.length > 0) {
      const prefix = parts[0];
      if (prefix === 'zh') return 'zh_CN';
      if (prefix === 'en') return 'en_US';
      if (prefix === 'ja') return 'ja_JP';
      if (prefix === 'ko') return 'ko_KR';
      if (prefix === 'fr') return 'fr_FR';
      if (prefix === 'es') return 'es_ES';
      if (prefix === 'de') return 'de_DE';
      if (prefix === 'pt') return 'pt_BR';
      if (prefix === 'ru') return 'ru_RU';
      if (prefix === 'ar') return 'ar_SA';
    }
    return null;
  }

  private isValidLocale(locale: string): boolean {
    const validLocales: string[] = ['zh_CN', 'en_US', 'ja_JP', 'ko_KR', 'fr_FR', 'es_ES', 'de_DE', 'pt_BR', 'ru_RU', 'ar_SA'];
    return validLocales.includes(locale);
  }

  isSystemLocaleSupported(): boolean {
    try {
      const systemLocale: string = i18n.System.getSystemLanguage();
      return this.convertLocale(systemLocale) !== null;
    } catch {
      return false;
    }
  }

  async init(context: common.Context): Promise<void> {
    this.context = context;
    try {
      this.pref = await preferences.getPreferences(context, this.PREF_NAME);
      const savedLocale = this.pref.getSync(this.KEY_LOCALE, '') as string;
      if (savedLocale && this.isValidLocale(savedLocale)) {
        this.currentLocale = savedLocale as LocaleCode;
      } else {
        this.currentLocale = this.getSystemLocale();
      }
      this.applyLocale();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[I18nManager] Init failed:', message);
      this.currentLocale = this.getSystemLocale();
    }
  }

  getLocale(): LocaleCode {
    return this.currentLocale;
  }

  async setLocale(locale: LocaleCode): Promise<void> {
    this.currentLocale = locale;
    if (this.pref) {
      try {
        this.pref.putSync(this.KEY_LOCALE, locale);
        this.pref.flush();
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        console.error('[I18nManager] Save locale failed:', message);
      }
    }
    this.applyLocale();
  }

  private applyLocale(): void {
    try {
      if (this.context) {
        // Read current system configuration via resourceManager (replacing deprecated getResourceConfiguration)
        const config = this.context.resourceManager.getConfigurationSync();
        if (config) {
          console.info('[I18nManager] System language from resourceManager');
        }
      }
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error('[I18nManager] Apply locale failed:', message);
    }
  }

  t(key: string, params?: Record<string, string | number>): string {
    // Use if-else chain instead of indexed access
    // Get translations for current locale
    let translations: TranslationMap;
    if (this.currentLocale === 'zh_CN') {
      translations = TRANSLATIONS.zh_CN;
    } else if (this.currentLocale === 'en_US') {
      translations = TRANSLATIONS.en_US;
    } else if (this.currentLocale === 'ja_JP') {
      translations = TRANSLATIONS.ja_JP;
    } else if (this.currentLocale === 'ko_KR') {
      translations = TRANSLATIONS.ko_KR;
    } else if (this.currentLocale === 'fr_FR') {
      translations = TRANSLATIONS.fr_FR;
    } else if (this.currentLocale === 'es_ES') {
      translations = TRANSLATIONS.es_ES;
    } else if (this.currentLocale === 'de_DE') {
      translations = TRANSLATIONS.de_DE;
    } else if (this.currentLocale === 'pt_BR') {
      translations = TRANSLATIONS.pt_BR;
    } else if (this.currentLocale === 'ru_RU') {
      translations = TRANSLATIONS.ru_RU;
    } else if (this.currentLocale === 'ar_SA') {
      translations = TRANSLATIONS.ar_SA;
    } else {
      translations = TRANSLATIONS.en_US;
    }

    // Get text
    let text = this.getTranslation(translations, key);
    if (text === '') {
      // Fallback to English
      text = this.getTranslation(TRANSLATIONS.en_US, key);
    }
    if (text === '') {
      return key;
    }

    // Replace params
    if (params) {
      const keys = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        const v = params[k];
        text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
      }
    }

    return text;
  }

  private getTranslation(translations: TranslationMap, key: string): string {
    // Use if-else instead of indexed access
    if (key === 'app_name') return translations.app_name;
    if (key === 'app_slogan') return translations.app_slogan;
    if (key === 'loading') return translations.loading;
    if (key === 'welcome') return translations.welcome;
    if (key === 'login') return translations.login;
    if (key === 'bookshelf') return translations.bookshelf;
    if (key === 'search') return translations.search;
    if (key === 'settings') return translations.settings;
    if (key === 'about') return translations.about;
    if (key === 'import_books') return translations.import_books;
    if (key === 'import') return translations.import;
    if (key === 'empty_shelf') return translations.empty_shelf;
    if (key === 'book_format') return translations.book_format;
    if (key === 'author') return translations.author;
    if (key === 'unknown_author') return translations.unknown_author;
    if (key === 'reading_progress') return translations.reading_progress;
    if (key === 'read_settings') return translations.read_settings;
    if (key === 'display_settings') return translations.display_settings;
    if (key === 'font_settings') return translations.font_settings;
    if (key === 'font') return translations.font;
    if (key === 'font_size') return translations.font_size;
    if (key === 'letter_spacing') return translations.letter_spacing;
    if (key === 'line_spacing') return translations.line_spacing;
    if (key === 'paragraph_spacing') return translations.paragraph_spacing;
    if (key === 'text_indent') return translations.text_indent;
    if (key === 'page_turn_settings') return translations.page_turn_settings;
    if (key === 'page_mode') return translations.page_mode;
    if (key === 'volume_key_turn') return translations.volume_key_turn;
    if (key === 'click_turn') return translations.click_turn;
    if (key === 'reading_theme') return translations.reading_theme;
    if (key === 'text_convert') return translations.text_convert;
    if (key === 'chinese_convert') return translations.chinese_convert;
    if (key === 'tts_settings') return translations.tts_settings;
    if (key === 'tts_speed') return translations.tts_speed;
    if (key === 'tts_pitch') return translations.tts_pitch;
    if (key === 'close') return translations.close;
    if (key === 'cancel') return translations.cancel;
    if (key === 'confirm') return translations.confirm;
    if (key === 'done') return translations.done;
    if (key === 'save') return translations.save;
    if (key === 'system_default') return translations.system_default;
    if (key === 'theme_light') return translations.theme_light;
    if (key === 'theme_sepia') return translations.theme_sepia;
    if (key === 'theme_dark') return translations.theme_dark;
    if (key === 'theme_auto') return translations.theme_auto;
    if (key === 'scroll') return translations.scroll;
    if (key === 'cover') return translations.cover;
    if (key === 'simulation') return translations.simulation;
    if (key === 'slide') return translations.slide;
    if (key === 'none') return translations.none;
    if (key === 'off') return translations.off;
    if (key === 'to_traditional') return translations.to_traditional;
    if (key === 'to_simplified') return translations.to_simplified;
    if (key === 'screen_settings') return translations.screen_settings;
    if (key === 'auto_brightness') return translations.auto_brightness;
    if (key === 'keep_screen_on') return translations.keep_screen_on;
    if (key === 'full_screen') return translations.full_screen;
    if (key === 'show_status_bar') return translations.show_status_bar;
    if (key === 'cache_settings') return translations.cache_settings;
    if (key === 'cache_size') return translations.cache_size;
    if (key === 'clear_cache') return translations.clear_cache;
    if (key === 'statistics') return translations.statistics;
    if (key === 'local_books') return translations.local_books;
    if (key === 'version') return translations.version;
    if (key === 'copyright') return translations.copyright;
    if (key === 'reader') return translations.reader;
    if (key === 'page_of') return translations.page_of;
    if (key === 'slide_to_read') return translations.slide_to_read;
    if (key === 'next_page') return translations.next_page;
    if (key === 'prev_page') return translations.prev_page;
    if (key === 'table_of_contents') return translations.table_of_contents;
    if (key === 'bookmarks') return translations.bookmarks;
    if (key === 'notes') return translations.notes;
    if (key === 'highlight') return translations.highlight;
    if (key === 'add_bookmark') return translations.add_bookmark;
    if (key === 'remove_bookmark') return translations.remove_bookmark;
    if (key === 'ocr_scan') return translations.ocr_scan;
    if (key === 'ocr_scan_hint') return translations.ocr_scan_hint;
    if (key === 'recognizing') return translations.recognizing;
    if (key === 'recognition_failed') return translations.recognition_failed;
    if (key === 'recognition_success') return translations.recognition_success;
    if (key === 'copy_text') return translations.copy_text;
    if (key === 'insert_to_book') return translations.insert_to_book;
    if (key === 'file_picker') return translations.file_picker;
    if (key === 'import_success') return translations.import_success;
    if (key === 'import_failed') return translations.import_failed;
    if (key === 'reading_stats') return translations.reading_stats;
    if (key === 'total_books') return translations.total_books;
    if (key === 'finished_books') return translations.finished_books;
    if (key === 'reading_days') return translations.reading_days;
    if (key === 'total_time') return translations.total_time;
    if (key === 'today') return translations.today;
    if (key === 'this_week') return translations.this_week;
    if (key === 'total') return translations.total;
    if (key === 'hours') return translations.hours;
    if (key === 'minutes') return translations.minutes;
    if (key === 'books_count') return translations.books_count;
    if (key === 'days_count') return translations.days_count;
    if (key === 'achievements') return translations.achievements;
    if (key === 'no_achievements') return translations.no_achievements;
    if (key === 'features_showcase') return translations.features_showcase;
    if (key === 'core_features') return translations.core_features;
    if (key === 'pure_reading') return translations.pure_reading;
    if (key === 'advanced_notes') return translations.advanced_notes;
    if (key === 'tts_feature') return translations.tts_feature;
    if (key === 'harmony_cards') return translations.harmony_cards;
    if (key === 'ebook_formats') return translations.ebook_formats;
    if (key === 'format_support') return translations.format_support;
    if (key === 'pdf') return translations.pdf;
    if (key === 'epub') return translations.epub;
    if (key === 'mobi') return translations.mobi;
    if (key === 'txt') return translations.txt;
    if (key === 'docx') return translations.docx;
    if (key === 'cbz') return translations.cbz;
    if (key === 'cbr') return translations.cbr;
    if (key === 'read_now') return translations.read_now;
    if (key === 'view_details') return translations.view_details;
    if (key === 'retry') return translations.retry;
    if (key === 'error') return translations.error;
    if (key === 'success') return translations.success;
    if (key === 'warning') return translations.warning;
    if (key === 'info') return translations.info;
    if (key === 'yes') return translations.yes;
    if (key === 'no') return translations.no;
    if (key === 'ok') return translations.ok;
    if (key === 'back') return translations.back;
    if (key === 'close_hint') return translations.close_hint;
    if (key === 'no_more') return translations.no_more;
    if (key === 'load_more') return translations.load_more;
    if (key === 'refreshing') return translations.refreshing;
    if (key === 'no_data') return translations.no_data;
    if (key === 'no_result') return translations.no_result;
    if (key === 'processing') return translations.processing;
    if (key === 'computing') return translations.computing;
    if (key === 'permission_denied') return translations.permission_denied;
    if (key === 'permission_required') return translations.permission_required;
    if (key === 'grant') return translations.grant;
    if (key === 'denied') return translations.denied;
    if (key === 'network_error') return translations.network_error;
    if (key === 'file_not_support') return translations.file_not_support;
    if (key === 'search_hint') return translations.search_hint;
    if (key === 'reading') return translations.reading;
    if (key === 'favorite') return translations.favorite;
    if (key === 'finished') return translations.finished;
    if (key === 'all') return translations.all;
    if (key === 'privacy_policy') return translations.privacy_policy;
    if (key === 'user_agreement') return translations.user_agreement;
    if (key === 'login_account') return translations.login_account;
    if (key === 'guest_mode') return translations.guest_mode;
    if (key === 'login_your_account') return translations.login_your_account;
    if (key === 'i_agree') return translations.i_agree;
    if (key === 'donation') return translations.donation;
    if (key === 'feedback') return translations.feedback;
    if (key === 'loading_resources') return translations.loading_resources;
    if (key === 'init_engine') return translations.init_engine;
    if (key === 'prepare_reading') return translations.prepare_reading;
    if (key === 'help_docs') return translations.help_docs;
    if (key === 'legal_support') return translations.legal_support;
    if (key === 'donate') return translations.donate;
    if (key === 'select_language') return translations.select_language;
    if (key === 'current_language') return translations.current_language;
    if (key === 'language_settings') return translations.language_settings;
    return '';
  }

  getDirection(): 'ltr' | 'rtl' {
    const localeInfo = SUPPORTED_LOCALES.find((item) => item.code === this.currentLocale);
    return localeInfo?.direction || 'ltr';
  }

  getLocaleInfo(): LocaleInfo | undefined {
    return SUPPORTED_LOCALES.find((item) => item.code === this.currentLocale);
  }

  getSupportedLocales(): LocaleInfo[] {
    return SUPPORTED_LOCALES;
  }
}

export const i18nManager = I18nManager.getInstance();
export const tr = (key: string, params?: Record<string, string | number>): string => {
  return i18nManager.t(key, params);
};
export default i18nManager;
