-- services/api/endpoints.lua
-- url拼接

local M = {}

-- 基础URL
M.BASE_URL = "https://www.zhihu.com"
M.API_URL = "https://www.zhihu.com/api/v4"
M.API_V3_URL = "https://www.zhihu.com/api/v3"
M.API_V5_URL = "https://www.zhihu.com/api/v5.1"

-- ============================================
-- 用户相关
-- ============================================

-- 当前用户信息
M.ME = M.API_URL .. "/me"

-- 用户信息
M.USER_INFO = M.API_URL .. "/members/%s"

-- 用户动态
M.USER_ACTIVITIES = M.API_URL .. "/members/%s/activities"

-- 用户回答
M.USER_ANSWERS = M.API_URL .. "/members/%s/answers"

-- 用户文章
M.USER_ARTICLES = M.API_URL .. "/members/%s/articles"

-- 用户提问
M.USER_QUESTIONS = M.API_URL .. "/members/%s/questions"

-- 用户专栏
M.USER_COLUMNS = M.API_URL .. "/members/%s/columns"

-- 关注用户
M.FOLLOW_USER = M.API_URL .. "/members/%s/followers"

-- 取消关注
M.UNFOLLOW_USER = M.API_URL .. "/members/%s/followers/%s"

-- ============================================
-- 内容相关
-- ============================================

-- 问题详情
M.QUESTION_DETAIL = M.API_URL .. "/questions/%s"

-- 问题回答列表
M.QUESTION_ANSWERS = M.API_URL .. "/questions/%s/answers?include=data%5B*%5D.author%2Ccontent%2Cvoteup_count%2Ccomment_count&offset=%s&limit=%s"

-- 回答详情
M.ANSWER_DETAIL = M.API_URL .. "/answers/%s"

-- 文章详情
M.ARTICLE_DETAIL = M.API_URL .. "/articles/%s"

-- 想法详情
M.PIN_DETAIL = M.API_URL .. "/pins/%s"

-- 视频详情
M.ZVIDEO_DETAIL = M.API_URL .. "/zvideos/%s"

-- ============================================
-- 推荐流
-- ============================================

-- 推荐内容
M.RECOMMEND_FEED = M.API_V3_URL .. "/topstory/recommend?limit=%s&offset=%s"

-- 热榜
M.HOT_LIST = M.API_V3_URL .. "/feed/topstory/hot-lists/total?limit=%s"

-- 日报最新
M.DAILY_LATEST = "https://news-at.zhihu.com/api/4/stories/latest"

-- 日报往期
M.DAILY_BEFORE = "https://news-at.zhihu.com/api/4/stories/before/%s"

-- 关注动态
M.FOLLOW_FEED = M.API_V3_URL .. "/moments_v3?feed_type=%s"

-- ============================================
-- 评论相关
-- ============================================

-- 评论列表
M.COMMENTS = M.API_URL .. "/comment_v5/%ss/%s/root_comment?offset=%s&limit=%s"

-- 子评论列表
M.CHILD_COMMENTS = M.API_URL .. "/comment_v5/comment/%s/child_comment"

-- 发表评论
M.POST_COMMENT = M.API_URL .. "/comment_v5/%ss/%s/comment"

-- 点赞评论
M.LIKE_COMMENT = M.API_URL .. "/comment_v5/comment/%s/reaction/like"

-- 踩评论
M.DISLIKE_COMMENT = M.API_URL .. "/comment_v5/comment/%s/reaction/dislike"

-- ============================================
-- 点赞/感谢
-- ============================================

-- 点赞回答
M.LIKE_ANSWER = M.API_URL .. "/answers/%s/voters"

-- 感谢回答
M.THANK_ANSWER = "https://www.zhihu.com/api/v4/zreaction"

-- ============================================
-- 收藏夹
-- ============================================

-- 收藏夹内容
M.COLLECTION_CONTENTS = M.API_URL .. "/collections/%s/contents?offset=%s"

-- 添加到收藏夹
M.ADD_TO_COLLECTION = M.API_URL .. "/collections/contents/%s/%s"

-- 用户收藏夹列表
M.USER_COLLECTIONS = M.API_URL .. "/members/%s/collections"

-- ============================================
-- 搜索
-- ============================================

-- 搜索
M.SEARCH = M.API_URL .. "/search_v3?q=%s&t=%s&offset=%s&limit=%s"

-- 搜索建议
M.SEARCH_SUGGEST = M.API_URL .. "/search/suggest?q=%s"

-- 热门搜索
M.TOP_SEARCH = M.API_URL .. "/search/top_search"

-- ============================================
-- 话题
-- ============================================

-- 话题详情
M.TOPIC_DETAIL = M.API_V5_URL .. "/topics/%s"

-- 话题内容
M.TOPIC_FEEDS = M.API_V5_URL .. "/topics/%s/feeds/%s"

-- ============================================
-- 其他
-- ============================================

-- 专栏内容
M.COLUMN_ITEMS = M.API_URL .. "/columns/%s/items"

-- 城市列表（主页Tab）
M.CITY_LIST = M.API_URL .. "/feed-root/sections/cityList"

-- 保存城市
M.SAVE_CITY = M.API_URL .. "/feed-root/sections/saveUserCity"

return M