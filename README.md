# cannyandachi - 캔냥닷치

> 치지직 방송 채팅을 캐릭터로 시각화하는 방송 도구 & 프록시 클라이언트
<img width="1280" height="420" alt="banner" src="https://github.com/user-attachments/assets/d4001b10-ff67-4bad-9d01-d0447159f601" />

![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Godot](https://img.shields.io/badge/Godot-4.5-blue.svg) ![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)

**캔낭닷치**는 치지직 방송에서 채팅 및 후원, 구독 정보를 받아와서, 캐릭터와 말풍선, 효과 등으로 시각화해주는
<br>방송 오버레이 프로그램 및 Socket.IO 프록시 클라이언트입니다.


> [!TIP] 
> **왜 이름이 캔냥닷치인가요?**
> <br>제 방송 팬 캐릭터인 *캔냥이* + 일본어 *토모다치* 를 섞어 만들어진 이름이에요.
> <br>기존에는 내수용으로만 사용하기 위해 개발한 프로그램이였는데, 기능을 이리저리 추가하면서 다른 스트리머분들도 활용하면 좋을 것 같다는 마음에 오픈소스로 공개하게 되었습니다!


---

## 🧩 주요 기능

- 💬 **실시간 채팅 시각화**
<br> 치지직 방송 채팅창에서 시청자 이름 및 채팅 내용을 받아와서 화면에 오버레이로 시각화

- 🎁 **후원/구독 이벤트**
<br> 치즈 후원 및 구독 이벤트 실시간 감지

- 👏 **스트리머와 시청자간의 상호작용**
<br> 시청자들은 명령어를 통해서 캐릭터를 조작하면서, 스트리머는 캐릭터를 클릭하고 드래그하여 조작함으로써 서로간에 상호작용이 가능

- 😀 **채팅 사용자 관리 기능**
<br> 접속한 적 있는 시청자 정보를 자동으로 기록하고, 언제든지 데이터베이스에 접근해서 캐릭터 색상이나 종류 등을 바꾸고 오버레이에서 아예 숨기는 등의 관리 기능

- 🧩 **확장성** (프록시)
<br> WebSocket을 사용하는 타 오버레이 프로그램과 호환 가능하여 기존의 다양한 확장프로그램 및 오버레이를 활용할 수 있음

- 🖥️ **투명 창 지원**
<br> 다른 애플리케이션 또는 OBS Studio 등에서 오버레이로 표시 가능


## ⚡ 사용 및 설치

![최신 릴리즈](https://github.com/BlacK-CHi/cannyadachi/releases/)를 다운로드받거나, 직접 소스코드를 내려받아 빌드하여 사용할 수 있습니다.
<br>프록시 서버의 경우 소스를 내려받은 후 직접 터미널에서 실행할 수도 있습니다.

### 채팅 오버레이
치지직 개발자 센터에서 애플리케이션 등록 후 Client ID, Client Secret을 인증설정 탭에 기입한 후 로그인하여 애플리케이션에 로그인합니다.
<br>로그인 후 웹브라우저에서 리디렉션된 주소 (``localhost:8080/?code=__________&state=____``) 에서 ``code=`` 뒷부분의 코드를 복사하여 인증 키 필드에 입력 후 인증을 진행해주세요.
<br>Token 필드에 값이 자동으로 입력되었다면, 마지막으로 아래의 토글 스위치를 눌러 프록시 서버에 접속합니다.
> [!IMPORTANT]
> ``채팅 메시지 조회``, ``채팅 메시지 쓰기``, ``후원 조회``, ``구독 조회`` 4개의 API Scopes가 애플리케이션에 할당되어야 합니다.


### 프록시 서버 실행 (터미널 사용)

1. git을 사용하여 이 저장소를 클론합니다.
   ```bash
   git clone https://github.com/BlacK-CHi/cannyadachi.git
   cd cannyadachi
   ```

2. 프록시 실행에 필요한 Python 의존성 패키지를 설치합니다.
   ```bash
   cd python_proxy
   pip install aiohttp python-socketio[asyncio]==4.6.1 pillow pystray
   ```

3. ``python_proxy/`` 내의 ``WSProxy.py``를 실행합니다.
   ```bash
   cd python_proxy
   python WSProxy.py # 또는 WSProxy.exe
   ```

> [!IMPORTANT]
> 기본적으로 프록시 서버는 ``ws://127.0.0.1:8765/ws`` 에서 실행됩니다.
> <br>최초 실행 시 자동으로 실행 위치에 설정 파일(``config.ini``)이 생성되며, 해당 파일을 통해 프록시 주소 및 포트를 변경할 수 있습니다.

  ```ini
  [SERVER]
  host = 127.0.0.1 <-- 해당 열에서 프록시 서버 주소를 바꿀 수 있습니다.
  port = 8765

  [LOGGING]
  file = proxy.log
  level = INFO
  ```

---

## 🛠️ 빌드
 ```bash
 git clone https://github.com/BlacK-CHi/cannyadachi.git
 cd cannyadachi
 ```
### 채팅 오버레이 (Godot)
Godot 4.5 이상 버전이 필요합니다.
<br>치지직 개발자 센터에서 애플리케이션 등록 후 Client ID, Client Secret을 ``mainProcess.gd``에 기입하거나 파일 등을 통해 불러온 후 사용해야 합니다.

> [!IMPORTANT]
> ``채팅 메시지 조회``, ``채팅 메시지 쓰기``, ``후원 조회``, ``구독 조회`` 4개의 API Scopes가 애플리케이션에 할당되어야 합니다.


### 웹소켓 프록시 서버
파이썬 3.7 이상 버전이 필요합니다. (개발은 v3.14에서 진행하였습니다)
<br>``python_proxy/`` 폴더 내의 ``requirements.txt`` 파일을 활용하여 필요한 패키지를 설치합니다.
```bash
pip install -r requirements.txt
```
- ``aiohttp`` >= 3.8.0
- `python-socketio[asyncio_client]` == 4.6.1
- `Pillow` >= 9.0.0
- `pystray` >= 0.19.0
- `pyinstaller` >= 5.0.0 - 단일 실행 파일로 만들 경우에만 사용합니다.

>[!WARNING]
>``python-socketio``의 경우 치지직 Session API에 명세된 클라이언트 버전 호환을 위해 무조건 ``4.6.1`` 버전으로 설치해야 합니다! (Socket.IO v2.x)

#### 프록시 서버 단일 실행 파일로 빌드하기
```bash
# pip install pyinstaller
cd python_proxy
pyinstaller --onefile --noconsole --add-data "trayicon.png;." WSProxy.py
```
