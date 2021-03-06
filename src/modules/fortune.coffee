# Programmers' fortune teller!
# This module is mostly a copy of (http://runjs.cn/code/ydp3it7b), so I do not want to convert it into Literate Coffee.
Module = require '../module'
{format} = require 'util'
{crc8} = require 'crc'

module.exports = class FortuneTeller extends Module
  today: (msg, args...) ->
    if args? and args.length > 0
      @whatif msg, args...
      return
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: new Fortune().tell()
      reply_to_message_id: msg.message_id
      parse_mode: 'markdown'
    .subscribe null, null, ->
      console.log "Fortune told!"

  whatif: (msg, args...) ->
    return if !args? or args.length is 0
    @telegram.sendMessage
      chat_id: msg.chat.id
      text: new Fortune().whatif args.join ' '
      reply_to_message_id: msg.message_id
      parse_mode: 'markdown'
    .subscribe null, (err) ->
      console.log "Can't complete `whatif` because #{err}"

  help:
    today: "/today - What's your fortune today?"
    whatif: "/whatif something - What if you do [something] today?"

# Impl (http://runjs.cn/code/ydp3it7b)
class Fortune
  constructor: ->
    @today = new Date
    @iday = @today.getFullYear() * 10000 + (@today.getMonth() + 1) * 100 + @today.getDate()

  tell: ->
    format "%s\n\n%s", @todayString(), @todayFortune()
  whatif: (koto) ->
    @star (@random (crc8 koto) / koto.length) % 5 + 1

  random: (indexSeed) ->
    n = @iday % 11117
    n = (n * n) % 11117 for i in [0..(100 + indexSeed - 1)]
    n
  randomPickArr: (array, size) ->
    result = array.slice 0

    for i in [0..(array.length - size - 1)]
      index = (@random i) % result.length
      result.splice index, 1

    result
  randomPick: (array, indexSeed) -> array[(@random indexSeed) % array.length]

  isWeekend: -> @today.getDay() is 0 or @today.getDay() is 6
  filter: ->
    if @isWeekend()
      activities.filter (it) -> it.weekend
    else
      activities
  parse: (ev) ->
    result =
      name: (ev.name.replace '%v', @randomPick varNames, 12
              .replace '%t', @randomPick tools, 11
              .replace '%l', (@random(12) % 247 + 30).toString())
      good: ev.good
      bad: ev.bad

  todayString: ->
    "今天是*" + @today.getFullYear() + "*年*" + (@today.getMonth() + 1) + "*月*" + @today.getDate() + "*日 星期*" + weeks[@today.getDay()] + "*"
  todayFortune: ->
    filtered = @filter()
    numGood = (@random 98) % 3 + 2
    numBad = (@random 87) % 3 + 2
    events = (@randomPickArr filtered, numGood + numBad).map (it) => @parse it

    """
*宜*
#{
  events[0..(numGood - 1)].map (it) -> it.name + " _#{it.good}_"
    .join '\n'
}

*不宜*
#{
  events[numGood...].map (it) -> it.name + " _#{it.bad}_"
    .join '\n'
}

面向 *#{@randomPick directions, 2}* 写程序，BUG 最少。
今日宜饮 #{(@randomPickArr drinks, 2).join ', '}
女神亲近指数 #{@star @random(6) % 5 + 1}
"""
  star: (num) -> "#{'\uD83C\uDF1D'.repeat num}#{'\uD83C\uDF1A'.repeat 5 - num}"

# Constants
weeks = ["日", "一", "二", "三", "四", "五", "六"]
directions = ["北方", "东北方", "东方", "东南方", "南方", "西南方", "西方", "西北方"]
activities = [
	{name:"写单元测试", good:"写单元测试将减少出错",bad:"写单元测试会降低你的开发效率"},
	{name:"洗澡", good:"你几天没洗澡了？",bad:"会把设计方面的灵感洗掉", weekend: true},
	{name:"锻炼一下身体", good:"",bad:"能量没消耗多少，吃得却更多", weekend: true},
	{name:"抽烟", good:"抽烟有利于提神，增加思维敏捷",bad:"除非你活够了，死得早点没关系", weekend: true},
	{name:"白天上线", good:"今天白天上线是安全的",bad:"可能导致灾难性后果"},
	{name:"重构", good:"代码质量得到提高",bad:"你很有可能会陷入泥潭"},
	{name:"使用%t", good:"你看起来更有品位",bad:"别人会觉得你在装逼"},
	{name:"跳槽", good:"该放手时就放手",bad:"鉴于当前的经济形势，你的下一份工作未必比现在强"},
	{name:"招人", good:"你面前这位有成为牛人的潜质",bad:"这人会写程序吗？"},
	{name:"面试", good:"面试官今天心情很好",bad:"面试官不爽，会拿你出气"},
	{name:"提交辞职申请", good:"公司找到了一个比你更能干更便宜的家伙，巴不得你赶快滚蛋",bad:"鉴于当前的经济形势，你的下一份工作未必比现在强"},
	{name:"申请加薪", good:"老板今天心情很好",bad:"公司正在考虑裁员"},
	{name:"晚上加班", good:"晚上是程序员精神最好的时候",bad:"", weekend: true},
	{name:"在妹子面前吹牛", good:"改善你矮穷挫的形象",bad:"会被识破", weekend: true},
	{name:"撸管", good:"避免缓冲区溢出",bad:"强撸灰飞烟灭", weekend: true},
	{name:"浏览成人网站", good:"重拾对生活的信心",bad:"你会心神不宁", weekend: true},
	{name:"命名变量\"%v\"", good:"",bad:""},
	{name:"写超过%l行的方法", good:"你的代码组织的很好，长一点没关系",bad:"你的代码将混乱不堪，你自己都看不懂"},
	{name:"提交代码", good:"遇到冲突的几率是最低的",bad:"你遇到的一大堆冲突会让你觉得自己是不是时间穿越了"},
	{name:"代码复审", good:"发现重要问题的几率大大增加",bad:"你什么问题都发现不了，白白浪费时间"},
	{name:"开会", good:"写代码之余放松一下打个盹，有益健康",bad:"小心被扣屎盆子背黑锅"},
	{name:"打DOTA", good:"你将有如神助",bad:"你会被虐的很惨", weekend: true},
	{name:"晚上上线", good:"晚上是程序员精神最好的时候",bad:"你白天已经筋疲力尽了"},
	{name:"修复BUG", good:"你今天对BUG的嗅觉大大提高",bad:"新产生的BUG将比修复的更多"},
	{name:"设计评审", good:"设计评审会议将变成头脑风暴",bad:"人人筋疲力尽，评审就这么过了"},
	{name:"需求评审", good:"",bad:""},
	{name:"上微博", good:"今天发生的事不能错过",bad:"今天的微博充满负能量", weekend: true},
	{name:"上AB站", good:"还需要理由吗？",bad:"满屏兄贵亮瞎你的眼", weekend: true},
	{name:"玩FlappyBird", good:"今天破纪录的几率很高",bad:"除非你想玩到把手机砸了", weekend: true}
]
varNames = ["jieguo", "huodong", "pay", "expire", "zhangdan", "every", "free", "i1", "a", "virtual", "ad", "spider", "mima", "pass", "ui"]
drinks = ["水","茶","红茶","绿茶","咖啡","奶茶","可乐","鲜奶","豆奶","果汁","果味汽水","苏打水","运动饮料","酸奶","酒"]
tools = ["Eclipse写程序", "MSOffice写文档", "记事本写程序", "Windows8", "Linux", "MacOS", "IE", "Android设备", "iOS设备"]
