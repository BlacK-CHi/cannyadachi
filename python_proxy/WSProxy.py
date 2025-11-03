# ────────────────────────────────────────── #
#            캔따개 - Godot WebSocket↔치지직 Socket.IO 프록시 서버
#                           Written by 블랙치이
# ────────────────────────────────────────── #

# 필요한 모듈 임포트
import asyncio
import configparser
import json
import logging
import sys
from typing import Dict, Set, Optional
from aiohttp import web
import socketio     # 참고: socketio는 4.6.1 버전을 사용합니다 (Socket.IO v2.x 호환)
import threading
from pathlib import Path
from PIL import Image
import pystray
import os

# PyInstaller 파일 경로 문제 해결 ────────────────────────────────────────── #
def resource_path(relative_path):
    try:
        # PyInstaller가 생성한 임시 폴더 
        base_path = sys._MEIPASS
    except Exception:
        # 일반 Python 실행
        base_path = os.path.abspath(".")
    
    return os.path.join(base_path, relative_path)


# ────────────────────────────────────────── #

AUTH_KEY_PAGE = """
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>캔냥닷치 로그인 성공</title>
        <style>
            html{
                background-color: #89E9FF;
            }
            
            .flexContainer{
                display: flex;
                justify-content: center;
                align-items: center;
            }

            .messageBox{
                background-color: white;
                padding: 20px;
                width: fit-content;
                border-radius: 20px;
                display: flex;
                flex-direction: column;
                text-align: center;
            }

            .message {
                display: flex;
                flex-direction: column;
                align-items: center;
            }

            .accessCode{
                text-align: center;
                border: 2px solid #89E9FF;
                border-radius: 10px;
                text-align: center;
                padding: 10px;
            }

            #copyBtn{
                background-color: #89E9FF;
                border: none;
                color: white;
                padding: 10px 20px;
                text-align: center;
                text-decoration: none;
                display: inline-block;
                font-size: 16px;
                border-radius: 5px;
                cursor: pointer;
            }

            #copyBtn:hover{
                background-color: #61C8E1;
            }
        </style>
    </head>

    <body>
        <div class="flexContainer">
            <div class="messageBox">
                <div class="message">
                    <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJAAAACQCAYAAADnRuK4AAAACXBIWXMAADXUAAA11AFeZeUIAAACj0lEQVR4nO3dPW4TURhAUQ/yDpAi0SIWEa8CpYcavAFYQ9iASQ09YhUuXUdCtIhIrMHsYF5x5b/4nHYyk6fx1Ss+jT2LBQAAAADXYKoXeH33bl/O//3je17DNTv1/X9RTgYBkQiIREAkAiIREImASJajPxjNGT58/ZYW8LBYzF7/2udE537/7UAkAiIREImASAREIiASAZEs65zh001cweD6z31OdOn33w5EIiASAZEIiERAJAIiERDJNJpD3Pz5day1cIaeXr2ZPW4HIhEQiYBIBEQiIBIBkQiIZDma82w2myMthXO0Xq9nj9uBSAREIiASAZEIiERAJAIimXa73ezzQKM5AM/baA5oByIREImASAREIiASAZEIiGS6vb2dnQNtt9tjrYUztFqtZo/bgUgERCIgEgGRCIhEQCQCIpn2+/3sHOjL07GWwjka/Q61HYhEQCQCIhEQiYBIBEQiIJLp/u/8HKh6+Pg+nV/fi37pzv3+2YFIBEQiIBIBkQiIREAkAiJZ1guM5hR1DnHo65/apd8/OxCJgEgERCIgEgGRCIhEQCQCIhEQiYBIBEQiIBIBkQiIREAkw++Fff7X/sH9y3b+SH3e5dDfuzr180yH/vzsQCQCIhEQiYBIBEQiIBIBkRz894FO7dK/d3Xu7EAkAiIREImASAREIiASAZEM3xs/cvfTe+Uv2Y+38++FH7EDkQiIREAkAiIREImASAREMu12uzQHWq/Xs8e3W3OiU1qt5uc8m80mXd8ORCIgEgGRCIhEQCQCIhEQyfLx8TFdYDRHGM0hOKzR51M/fzsQiYBIBEQiIBIBkQiIREAk+b3xVX0e5dqNnsc6NDsQiYBIBEQiIBIBkQiIREAk/wHn/4u71lsufwAAAABJRU5ErkJggg==" alt="Cannyang Dutch Logo" width="72px"/>
                    <p><b>치지직 애플리케이션에 로그인되었습니다!</b></p>
                    <p>아래의 인증 키를 캔냥닷치 오버레이에 입력해주세요.</p>
                
                    <div class="accessCode">
                        <p class="code" id="codeText" style="margin: 2px;">
                            올바르지 않은 경로로 접근했습니다. 다시 시도해 주세요.
                        </p>
                    </div>
                    <button id="copyBtn" style="margin-top: 10px;" onclick="copyCode()">인증 키 복사</button>
            </div>
        </div>

        <script>
            const params = new URLSearchParams(window.location.search);
            const code = params.get('code');
            const codeText = document.getElementById('codeText');
            const copyBtn = document.getElementById('copyBtn');
            
            if (code) {
                codeText.textContent = code;
                copyBtn.style.display = 'inline-block';
            }
            
            function copyCode() {
                navigator.clipboard.writeText(code).then(() => {
                    alert('인증 키가 복사되었습니다!');
                });
            }
        </script>
    </body>
</html>

"""


CONFIG_FILE = Path("config.ini")
config = configparser.ConfigParser()

DEFAULT_CONFIG = {
    'SERVER': {
        'host' : '127.0.0.1',
        'port' : '8765'
    },
    'LOGGING': {
        'file' : 'proxy.log',
        'level' : 'INFO'
    }
}

# 설정 파일을 불러오는 함수 -> 설정 파일이 없으면 DEFAULT_CONFIG를 참고하여 새로 생성합니다.
def load_config():
    if not CONFIG_FILE.exists():
        logger.info("설정 파일을 찾을 수 없습니다. 기본 설정으로 생성합니다...")
        config.read_dict(DEFAULT_CONFIG)
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            config.write(f)
        logger.info("기본 설정 파일이 생성되었습니다.")

    else:
        config.read(CONFIG_FILE, encoding='utf-8')
        logger.info("설정 파일을 불러왔습니다.")

    return config

logging.basicConfig(                    # 초기 로그 설정 (추후 설정 파일에 의해 덮어쓰여짐)
    level=logging.INFO,
    format='[%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# 설정 파일 불러오기
config = load_config()

SERVER_HOST = config.get('SERVER', 'host', fallback='127.0.0.1')
SERVER_PORT = config.getint('SERVER', 'port', fallback=8765)
LOG_FILE = config.get('LOGGING', 'file', fallback='proxy.log')
LOG_LEVEL = config.get('LOGGING', 'level', fallback='INFO').upper()

log_level_mapping = {
    'DEBUG': logging.DEBUG,
    'INFO': logging.INFO,
    'WARNING': logging.WARNING,
    'ERROR': logging.ERROR,
    'CRITICAL': logging.CRITICAL
}

logging.basicConfig(                    # 로그 설정을 설정 파일에 맞게 재정의합니다.
    level=log_level_mapping.get(LOG_LEVEL, logging.INFO),
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler()
    ],  
    force=True
)
logger = logging.getLogger(__name__)

sioClient = socketio.AsyncClient(       #Socket.IO 클라이언트 인스턴스 생성
    reconnection=True,
    reconnection_delay=1,
    reconnection_delay_max=5,
    reconnection_attempts=100,
    engineio_logger=False,
    logger=False
)
# ────────────────────────────────────────── #
#                       Godot과 통신할 웹소켓 서버 클래스
# ────────────────────────────────────────── #
# - Godot 클라이언트와의 웹소켓 통신 및 Socket.IO 클라이언트와의 중계처리를 담당합니다.
# 
# - handleWS : 기본적인 웹소켓 연결을 처리합니다.
# - handleGodotMsg : Godot 클라이언트로부터 수신된 메시지를 처리합니다.
# - connectChzzk/disconnectChzzk : 치지직 API와의 연결을 관리합니다.
# - broadcast : 접속된 모든 Godot 클라이언트에게 메시지를 전송합니다.
# - forwardFromChzzk : 치지직 API로부터 수신된 이벤트를 Godot 클라이언트로 전달합니다.
# - disconnectAll : 모든 접속된 Godot 클라이언트의 연결을 해제합니다. (치지직과의 연결도 해제합니다)

class godotWSServer:
    def __init__(self):
        self.clients: Set[web.WebSocketResponse] = set()
        self.accessToken: Optional[str] = None      #치지직 액세스 토큰
        self.socketUrl: Optional[str] = None        #치지직 소켓 URL
        self.connectToChzzk = False                 #치지직 API와의 연결 상태
        self.is_running = True                      #서버 실행 상태 플래그
    
    # 기본적인 웹소켓 연결 및 메시지 수신 처리
    async def handleWS(self, request):
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        self.clients.add(ws)

        logger.info("새로운 클라이언트와 연결되었습니다.")

        try: # Godot 클라이언트로부터 메시지 수신 대기
            async for msg in ws:
                if msg.type == web.WSMsgType.TEXT: # 텍스트 형태의 메시지를 수신할 경우 handleGodotMsg 메서드로 전달
                    await self.handleGodotMsg(msg.data, ws) 
                elif msg.type == web.WSMsgType.ERROR:
                    logger.error(f'WebSocket 연결이 끊어졌습니다: {ws.exception()}')
                elif msg.type == web.WSMsgType.CLOSED:
                    break

        finally: # 연결 종료 및 클라이언트 부재 시 치지직과 연결 해제
            self.clients.remove(ws)
            if len(self.clients) == 0: # 연결된 클라이언트가 없을 경우 치지직과의 연결을 자동으로 해제합니다.
                logger.info("접속된 클라이언트가 없습니다. 치지직 API에서 연결 해제합니다.")
                await self.disconnectChzzk()
        
        return ws
    
    # Godot 클라이언트로부터 수신된 메시지 처리 ──────────────────────────────────────────
    async def handleGodotMsg(self, data: str, senderWS: web.WebSocketResponse):
        try:
            message = json.loads(data) # 일단 수신한 메시지를 JSON으로 파싱 시도
            command = message.get("command") # 메시지에서 명령어 (command) 추출

            # 추출된 명령어에 따라 분기 처리를 수행합니다.
            # - set_token : 액세스 토큰, 소켓 접속 URL 설정
            # - connect : 치지직 API와 연결 시도
            # - disconnect : 치지직 API와 연결 해제
            # - emit : Socket.IO 이벤트 전송 (웬만하면 사용할 일 없음)
            # 그 외의 알 수 없는 명령어는 경고 로그를 출력합니다

            if command == "set_token":
                self.accessToken = message.get("access_token") # 메시지에서 액세스 토큰 및 소켓 URL 추출
                self.socketUrl = message.get("socket_url")
                logger.debug(self.socketUrl)
                await self.broadcast({ # Godot 클라이언트에게 접속 정보 설정 완료 메시지 전송
                    "type": "token_set",
                    "status": "success"
                })
                logger.info("Godot에서부터 접속 정보를 받아왔습니다.")

            elif command == "connect":
                await self.connectChzzk()

            elif command == "disconnect":
                await self.disconnectChzzk()
            
            elif command == "emit":
                event = message.get("event")
                payload = message.get("payload", {})
                await sioClient.emit(event, payload)

            else:
                logger.warning(f"알 수 없는 명령어: {command}")
            
        # 만약 JSON 파싱에 실패하거나, 메시지 처리 중 오류가 발생할 경우 에러 로그를 출력하게 됩니다.
        except json.JSONDecodeError:
            logger.error("수신한 값의 디코딩에 실패했습니다.")
        except Exception as e:
            logger.error(f"메시지를 처리하는 도중 오류가 발생했습니다: {e}")

    # 치지직 API와 연결 수립 ──────────────────────────────────────────
    async def connectChzzk(self):
        if not self.socketUrl or not self.accessToken:  # 소켓 URL 또는 액세스 토큰이 비어있는 경우 오류 메시지 전송
            await self.broadcast({
                "type": "error",
                "message": "액세스 토큰 또는 소켓 URL이 입력되지 않았습니다."
            })
            return
        
        try:
            logger.info("치지직 API에 연결 중입니다...")

            headers = {
                "Authorization": f"Bearer {self.accessToken}"   # 액세스 토큰은 인증 헤더에 포함합니다.
            }

            await sioClient.connect(self.socketUrl, headers=headers, transports=['websocket'])
            self.connectToChzzk = True                          # 연결 상태 플래그 설정
            await self.broadcast({
                "type": "connection_status",
                "status": "connected"
            })

        except Exception as e:                                  # 연결 실패 시 오류 메시지 전송
            logger.error(f"치지직 API와 연결하지 못했습니다: {e}")
            await self.broadcast({
                "type": "error",
                "message": f"연결 오류가 발생했습니다: {e}"
            })
    
    # 치지직 API와 연결 해제 ──────────────────────────────────────────
    async def disconnectChzzk(self):
        try:
            if sioClient.connected:
                await sioClient.disconnect()
                self.connectToChzzk = False
                await self.broadcast({
                    "type": "connection_status",
                    "status": "disconnected"
                })

        except Exception as e:
            logger.error(f"연결 해제 도중 문제가 발생했습니다: {e}")

    # 모든 접속된 Godot 클라이언트에게 메시지 전송 ──────────────────────────────────────────
    async def broadcast(self, message: Dict):
        disconnected = set()
        for ws in self.clients:
            try:
                await ws.send_str(json.dumps(message)) # Dict 형태의 메시지를 JSON 문자열로 변환하여 전송
            except Exception as e:
                logger.error(f"클라이언트로 메시지 전송에 실패했습니다: {e}")
                disconnected.add(ws)

        self.clients -= disconnected

    # 치지직 API로부터 수신된 이벤트를 Godot 클라이언트로 전달 ──────────────────────────────────────────
    async def forwardFromChzzk(self, event: str, data: Dict):
        message = {
            "type": "socket_event",
            "event": event,
            "data": data
        }
        await self.broadcast(message)

    # 모든 클라이언트 연결 해제 및 치지직과 연결 해제 ──────────────────────────────────────────
    async def disconnectAll(self):
        logger.info("모든 클라이언트 연결을 해제합니다")
        for ws in list(self.clients):
            try:
                await ws.close()
            except:
                pass
            self.clients.clear()
                
        if self.connectToChzzk:
            await self.disconnectChzzk()

wsServer = godotWSServer()

# ────────────────────────────────────────── #
#                          Socket.IO 이벤트 핸들러들
# ────────────────────────────────────────── #
# - 기본적으로 모든 이벤트는 비슷한 구조를 가집니다.
# - 수신된 데이터를 JSON으로 파싱 시도 후, wsServer의 forwardFromChzzk 메서드를 통해 Godot으로 전달합니다.
# - SYSTEM, CHAT, DONATION, SUBSCRIPTION 이벤트는 별도 처리 후, 그 외의 이벤트들은 catch_all 핸들러에서 처리합니다.


# 접속/접속 해제 이벤트 ──────────────────────────────────────────
@sioClient.event
async def connect():
    logger.info("치지직 API와 연결되었습니다!") 
    await wsServer.broadcast({
        "type": "socket_io_status",
        "status": "connected"
    })

@sioClient.event
async def disconnect():
    logger.info("치지직 API와 연결 해제되었습니다.")
    await wsServer.broadcast({
        "type": "socket_io_status",
        "status": "disconnected"
    })

# 시스템 메시지 수신 시 ──────────────────────────────────────────
@sioClient.on("SYSTEM")
async def on_system_message(data):
    if isinstance(data, str):               # 문자열인 경우 JSON 파싱 시도 
        try:
            data = json.loads(data)
        except json.JSONDecodeError:
            logger.warning("SYSTEM: non-JSON string received")

    if isinstance(data, dict):              # 딕셔너리 형태일 경우 추가 처리
        message_type = data.get("type")
        if message_type == "connected":
            session_data = data.get("data", {})
            session_key = session_data.get("sessionKey")

            if session_key:                 # sessionKey가 존재할 경우 Godot 클라이언트로 전송
                logger.info(f"sessionKey 취득 완료: {session_key}")
                await wsServer.broadcast({
                    "type": "session_key",
                    "session_key": session_key
                })

    await wsServer.forwardFromChzzk("SYSTEM", data)


# 채팅 메시지 수신 시 ──────────────────────────────────────────
@sioClient.on("CHAT")
async def on_chat_message(data): # 채팅 메시지 수신
    logger.info(f"CHAT message received: {data[:100] if isinstance(data, str) else data}") # 수신된 메시지 일부 출력 (로깅용)
    if isinstance(data, str):
        try:
            data = json.loads(data)     # 문자열인 경우 JSON 파싱 시도
        except json.JSONDecodeError:
            pass                        # 파싱 실패 시 원본 문자열 유지
        
    await wsServer.forwardFromChzzk("CHAT", data)

# 치즈 후원 이벤트 발생 시 ──────────────────────────────────────────
@sioClient.on("DONATION")
async def on_donation_message(data):
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except json.JSONDecodeError:
            pass
    
    await wsServer.forwardFromChzzk("DONATION", data)

# 구독 이벤트 발생 시 ──────────────────────────────────────────
@sioClient.on("SUBSCRIPTION")
async def on_subscription_message(data):
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except json.JSONDecodeError:
            pass
    
    await wsServer.forwardFromChzzk("SUBSCRIPTION", data)

# 그 외 모든 이벤트 ──────────────────────────────────────────
@sioClient.on('*')
async def catch_all(event, *args):
    logger.info(f"Event '{event}' received with args: {args}")
    
    # 첫 번째 인자 추출
    data = args[0] if args else {}
    
    # 문자열이면 JSON 파싱 시도
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except json.JSONDecodeError:
            # 파싱 실패하면 수신한 값을 그대로 (raw값) 사용
            data = {"raw": data}
    
    # 딕셔너리가 아니면 딕셔너리의 형태로 변환
    if not isinstance(data, dict):
        data = {"raw": str(data)}

    await wsServer.forwardFromChzzk(event, data)



# ────────────────────────────────────────── #
#                          웹소켓 서버 (프록시 서버) 시작
# ────────────────────────────────────────── #


async def auth_key_handler(request):
    return web.Response(text=AUTH_KEY_PAGE, content_type='text/html')

app = web.Application()
app.router.add_get('/ws', wsServer.handleWS)

async def start_server():
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, SERVER_HOST, SERVER_PORT) # 설정 파일을 참고하는 경우 기본값은 127.0.0.1:8765입니다.
    await site.start()

    httpApp = web.Application()
    httpApp.router.add_get('/', auth_key_handler)
    http_runner = web.AppRunner(httpApp)
    
    await http_runner.setup()
    http_site = web.TCPSite(http_runner, SERVER_HOST, 8080)
    await http_site.start()
    
    print("===================================================================")
    print("                캔따개 ─ WebSocket-Socket.IO 프록시               ")
    print("                Written by 블랙치이 (@BKCHI_shelter)               ")
    print("===================================================================")
    logger.info(f"웹소켓 서버가 시작되었습니다. (엔드포인트: ws://{SERVER_HOST}:{SERVER_PORT})")
    logger.info(f"인증키 수신 페이지가 시작되었습니다. (주소: http://{SERVER_HOST}:8080)")

# ────────────────────────────────────────── #
#                          시스템 트레이 아이콘 설정 및 트레이 실행
# ────────────────────────────────────────── #

def load_icon_image():              # 시스템 트레이 아이콘 이미지 로드
    icon_path = resource_path('trayicon.png')
    return Image.open(icon_path)


def open_config_file(icon, item):   # 설정 파일 열기
    os.startfile(CONFIG_FILE)
    # os.system(f'open {configFile}')      # macOS에서 컴파일하는 경우 주석 제거
    # os.system(f'xdg-open {configFile}')  # 리눅스에서 컴파일하는 경우 주석 제거

def open_log_file(icon, item):      # 로그 파일 열기
    os.startfile(LOG_FILE)
    # os.system(f'open {LOG_FILE}')      # macOS에서 컴파일하는 경우 주석 제거
    # os.system(f'xdg-open {LOG_FILE}')  # 리눅스에서 컴파일하는 경우 주석 제거

def disconnect_clients(icon, item): # 모든 클라이언트 연결 해제
    logger.info("모든 클라이언트의 연결을 해제합니다...")
    asyncio.run_coroutine_threadsafe(wsServer.disconnectAll(), loop)

def stop_server(icon, item):        # 서버 종료
    logger.info("서버를 종료합니다...")
    wsServer.is_running = False
    icon.stop()
    loop.call_soon_threadsafe(loop.stop)

def system_tray_setup():            # 시스템 트레이 아이콘 및 메뉴 설정
    icon_image = load_icon_image()
    menu = pystray.Menu(
        pystray.MenuItem(
            lambda _: f"프록시 서버 주소 : ws://{SERVER_HOST}:{SERVER_PORT}/ws",
            None, enabled=False
        ),
        pystray.MenuItem(
            lambda _: f"HTTP 서버 주소 : http://{SERVER_HOST}:8080",
            None, enabled=False
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("설정 파일 열기", open_config_file),
        pystray.MenuItem("로그 파일 열기", open_log_file),
        pystray.MenuItem("클라이언트 연결 해제", disconnect_clients),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("종료", stop_server)
    )

    icon = pystray.Icon(
        "캔따개 - ",
        icon_image,
        f"ws://{SERVER_HOST}:{SERVER_PORT}/ws 에서 실행 중",
        menu
    )

    return icon

loop = None

def run_asyncio_loop(loop):
    asyncio.set_event_loop(loop)
    loop.run_forever()

# 여기서부터 사실상 서버 실행 진입점 ────────────────────────────────────────── #
if __name__ == '__main__':
    logger.info("프록시 서버를 시작합니다...")

    # Asyncio 이벤트 루프 생성 & 프록시 서버 시작
    loop = asyncio.new_event_loop()
    loop.run_until_complete(start_server())

    # Asyncio 이벤트 루프 (프록시 서버)를 별도 스레드에서 실행합니다.
    asyncio_thread = threading.Thread(target=run_asyncio_loop, args=(loop,), daemon=True)
    asyncio_thread.start()

    # 시스템 트레이 아이콘 실행 (메인 스레드에서 실행)
    icon = system_tray_setup()
    icon.run()


