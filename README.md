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

---
<div align="center">

### [프록시 다운로드](https://github.com/BlacK-CHi/cannyadachi/releases/tag/proxy_v1.1.0) | [오버레이 다운로드](https://github.com/BlacK-CHi/cannyadachi/releases/tag/overlay_v1.1.1)
**🔌 [빠른 시작](https://github.com/BlacK-CHi/cannyadachi/blob/main/docs/quickstart.md)  • 👤 [사용자 관리]()  • 😊 [아바타 관리](https://github.com/BlacK-CHi/cannyadachi/blob/main/docs/avatar.md)**

</div>

---

## 🛠️ 빌드
> [!WARNING]
> 아직 빌드 관련 설명은 작성 중에 있습니다! 조금만 기다려주세요!

<details>
<summary>접기/펼치기</summary>
 
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
</details>
