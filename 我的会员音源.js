/*!
 * @name 我的会员音源 (网易云 + QQ)
 * @description 用「我的音源」本地后端(端口3000)里我自己的网易云/QQ会员登录态换取播放地址。仅用于个人自有账号播放辅助，不绕过付费与会员权益。
 * @version 1.0.0
 * @author me
 */

// ============ 使用说明 ============
// 1. 先双击「我的音源\启动.bat」把本地后端跑起来(窗口保持开启)。
// 2. lx 设置 → 自定义源 → 导入本文件。
// 3. 登录信息(cookie)在「我的音源」文件夹下的 .netease-cookie / .qq-cookie，
//    过期时更新那两个文件即可，本脚本无需改动。

// ============ 配置 ============
// 「我的音源」后端监听的地址；启动脚本已锁到 127.0.0.1:3000
const API_BASE = 'http://127.0.0.1:3000'

// 声明本源支持的平台与音质。
// 音质字符串必须是 lx 认识的枚举，mineradio 会把它归一化成自己的档位。
const SOURCES = {
  wy: {
    name: '网易云(我的会员)',
    type: 'music',
    actions: ['musicUrl'],
    qualitys: ['128k', '320k', 'flac', 'flac24bit'],
  },
  tx: {
    name: 'QQ音乐(我的会员)',
    type: 'music',
    actions: ['musicUrl'],
    qualitys: ['128k', '320k', 'flac', 'flac24bit'],
  },
}

// lx 音质枚举 -> mineradio 的 quality 参数
const QUALITY_MAP = {
  '128k': 'standard',
  '192k': 'standard',
  '320k': 'exhigh',
  flac: 'lossless',
  flac24bit: 'hires',
  hires: 'hires',
  master: 'jymaster',
}

// ============ 小工具 ============
function toQualityParam(q) {
  return QUALITY_MAP[q] || 'exhigh'
}

// 封装 lx.request 成 Promise，返回已解析的 JSON body
function httpGetJson(url) {
  return new Promise((resolve, reject) => {
    globalThis.lx.request(
      url,
      { method: 'GET', timeout: 20000, headers: { 'User-Agent': 'lx-custom-source' } },
      (err, resp) => {
        if (err) return reject(err)
        const body = resp && resp.body
        if (body == null) return reject(new Error('empty response'))
        if (typeof body === 'string') {
          try { return resolve(JSON.parse(body)) } catch (e) { return reject(new Error('bad json')) }
        }
        resolve(body)
      }
    )
  })
}

function firstArtistName(musicInfo) {
  if (!musicInfo) return ''
  if (Array.isArray(musicInfo.singer)) {
    return musicInfo.singer.map(s => (s && (s.name || s)) || '').filter(Boolean).join(' ')
  }
  return musicInfo.singer || musicInfo.artist || ''
}

// 从 lx 传入的 musicInfo 里尽量取出平台原生 id
function extractNativeId(source, musicInfo) {
  if (!musicInfo) return ''
  // lx 内置源的字段：songmid 通常就是网易云数字id / QQ 的 songmid
  return (
    musicInfo.songmid ||
    musicInfo.songId ||
    musicInfo.id ||
    (musicInfo.hash /* kg 之类，用不到 */ ? '' : '') ||
    ''
  )
}

// ============ 取地址：网易云 ============
async function getNeteaseUrl(musicInfo, quality) {
  const quality2 = toQualityParam(quality)

  // 1) 优先透传原生 id
  let id = extractNativeId('wy', musicInfo)

  // 2) 拿不到 id 就用 歌名+歌手 反查
  if (!id) {
    const kw = [musicInfo && musicInfo.name, firstArtistName(musicInfo)].filter(Boolean).join(' ')
    if (!kw) throw new Error('no id and no keyword')
    const res = await httpGetJson(`${API_BASE}/api/search?keywords=${encodeURIComponent(kw)}&limit=5`)
    const song = (res.songs || []).find(s => s && s.id)
    if (!song) throw new Error('search miss')
    id = song.id
  }

  const info = await httpGetJson(
    `${API_BASE}/api/song/url?id=${encodeURIComponent(id)}&quality=${quality2}`
  )
  if (info && info.url && info.playable !== false) return info.url
  throw new Error((info && (info.message || info.reason)) || 'netease url unavailable')
}

// ============ 取地址：QQ ============
async function getQQUrl(musicInfo, quality) {
  const quality2 = toQualityParam(quality)

  let mid = extractNativeId('tx', musicInfo)
  let mediaMid = (musicInfo && (musicInfo.mediaMid || musicInfo.media_mid || musicInfo.strMediaMid)) || ''

  // 反查兜底：用 QQ 搜索拿 mid + mediaMid
  if (!mid) {
    const kw = [musicInfo && musicInfo.name, firstArtistName(musicInfo)].filter(Boolean).join(' ')
    if (!kw) throw new Error('no mid and no keyword')
    const res = await httpGetJson(`${API_BASE}/api/qq/search?keywords=${encodeURIComponent(kw)}&limit=8`)
    const song = (res.songs || []).find(s => s && (s.mid || s.songmid))
    if (!song) throw new Error('search miss')
    mid = song.mid || song.songmid
    mediaMid = mediaMid || song.mediaMid || ''
  }

  let u = `${API_BASE}/api/qq/song/url?mid=${encodeURIComponent(mid)}&quality=${quality2}`
  if (mediaMid) u += `&mediaMid=${encodeURIComponent(mediaMid)}`
  const info = await httpGetJson(u)
  if (info && info.url && info.playable !== false) return info.url
  throw new Error((info && (info.message || info.reason)) || 'qq url unavailable')
}

// ============ 注册请求处理器 ============
const { EVENT_NAMES, request, on, send } = globalThis.lx

on(EVENT_NAMES.request, ({ source, action, info }) => {
  if (action !== 'musicUrl') return Promise.reject(new Error('unsupported action: ' + action))
  const musicInfo = info && info.musicInfo
  const quality = (info && info.type) || '320k'
  if (source === 'wy') return getNeteaseUrl(musicInfo, quality)
  if (source === 'tx') return getQQUrl(musicInfo, quality)
  return Promise.reject(new Error('unsupported source: ' + source))
})

// ============ 声明就绪 ============
send(EVENT_NAMES.inited, {
  status: true,
  openDevTools: false,
  sources: SOURCES,
})
