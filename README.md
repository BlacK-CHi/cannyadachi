# 캔낭닷치 (Cannyadachi)

> 치지직(CHZZK) 라이브스트림 채팅을 캐릭터로 시각화하는 도구

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Godot](https://img.shields.io/badge/Godot-4.5-blue.svg)
![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)

## 📖 소개

캔낭닷치는 치지직(CHZZK) 라이브 스트리밍 플랫폼의 채팅을 귀여운 캐릭터로 시각화하는 데스크톱 애플리케이션입니다. 시청자들의 채팅이 화면에 캐릭터로 표시되어, 방송을 더욱 생동감 있고 재미있게 만들어줍니다.

### ✨ 주요 기능

- 🎭 **실시간 채팅 시각화**: 치지직 채팅 메시지를 실시간으로 캐릭터 애니메이션으로 표현
- 💬 **채팅 버블**: 사용자의 메시지를 캐릭터 위에 말풍선으로 표시
- 🎨 **다양한 캐릭터 애니메이션**: 서기, 앉기, 이동, 점프, 낙하, 넘어지기 등 다양한 동작
- 🌈 **사용자별 색상 구분**: 각 사용자마다 고유한 색상으로 캐릭터 표시
- 🎁 **후원/구독 이벤트**: 치즈 후원 및 구독 이벤트 실시간 감지
- 🖥️ **투명 창 지원**: 다른 애플리케이션 위에 오버레이로 표시 가능

## 🏗️ 구조

이 프로젝트는 두 가지 주요 구성 요소로 이루어져 있습니다:

### 1. Godot 클라이언트
- **엔진**: Godot 4.5
- **역할**: 캐릭터 렌더링, 애니메이션 처리, UI 표시
- **주요 파일**:
  - `mainWindow/mainProcess.gd`: 메인 프로세스 및 인증 처리
  - `class/chzzkHandler.gd`: 치지직 이벤트 핸들러
  - `class/userManager.gd`: 채팅 사용자 관리
  - `class/proxyClient.gd`: 프록시 서버와의 WebSocket 통신
  - `character/`: 캐릭터 스프라이트 및 씬 파일

### 2. Python 프록시 서버
- **파일**: `python_proxy/WSProxy.py`
- **역할**: 치지직 Socket.IO API와 Godot WebSocket 간 중계
- **기능**:
  - 치지직 Socket.IO 서버와 연결
  - Godot 클라이언트와 WebSocket 통신
  - 이벤트 라우팅 및 메시지 변환
  - 시스템 트레이 아이콘 제공

## 🔧 설치 방법

### 필수 요구사항

#### Godot 클라이언트
- [Godot Engine 4.5](https://godotengine.org/download) 이상

#### Python 프록시 서버
- Python 3.7 이상
- 필요한 패키지:
  ```bash
  pip install aiohttp python-socketio[asyncio]==4.6.1 pillow pystray
  ```

### 설치 단계

1. **저장소 클론**
   ```bash
   git clone https://github.com/BlacK-CHi/cannyadachi.git
   cd cannyadachi
   ```

2. **Python 의존성 설치**
   ```bash
   cd python_proxy
   pip install aiohttp python-socketio[asyncio]==4.6.1 pillow pystray
   ```

3. **Godot 프로젝트 열기**
   - Godot Engine을 실행
   - "Import" 클릭
   - `project.godot` 파일 선택하여 프로젝트 열기

## 🚀 사용 방법

### 1단계: 프록시 서버 실행

```bash
cd python_proxy
python WSProxy.py
```

프록시 서버가 시작되면 시스템 트레이에 아이콘이 표시됩니다.
- 기본 주소: `ws://127.0.0.1:8765/ws`
- 설정 파일: `config.ini` (자동 생성됨)

#### 프록시 서버 설정

`config.ini` 파일에서 서버 설정을 변경할 수 있습니다:

```ini
[SERVER]
host = 127.0.0.1
port = 8765

[LOGGING]
file = proxy.log
level = INFO
```

### 2단계: Godot 클라이언트 실행

1. Godot 에디터에서 프로젝트 열기
2. F5 키를 눌러 프로젝트 실행 (또는 상단의 재생 버튼 클릭)

### 3단계: 치지직 인증

1. **클라이언트 ID/Secret 설정**
   - 치지직 개발자 콘솔에서 OAuth 애플리케이션 생성
   - Client ID와 Client Secret을 앱에 입력

2. **인증 진행**
   - "인증" 버튼 클릭
   - 브라우저에서 치지직 로그인 및 권한 승인
   - 리다이렉트 URL에서 인증 코드 복사하여 입력

3. **채널 연결**
   - Access Token이 자동으로 설정됨
   - "연결" 버튼을 클릭하여 채팅 수신 시작

### 4단계: 캐릭터 확인

채팅 메시지가 들어오면 화면에 캐릭터가 나타나며, 말풍선으로 메시지가 표시됩니다!

## 🎮 캐릭터 동작

캐릭터는 다음과 같은 다양한 애니메이션을 지원합니다:

- **stand**: 서있는 자세 (기본)
- **sit**: 앉아있는 자세
- **move**: 걷기/이동
- **jump**: 점프
- **fall**: 낙하
- **idle**: 대기 애니메이션
- **knock**: 넘어지기

## 📁 프로젝트 구조

```
cannyadachi/
├── character/              # 캐릭터 리소스
│   ├── sprite/            # 캐릭터 스프라이트 이미지
│   ├── character.tscn     # 캐릭터 씬
│   └── chatBubble.tscn    # 채팅 버블 씬
├── class/                 # 핵심 로직 클래스
│   ├── chzzkHandler.gd    # 치지직 이벤트 처리
│   ├── proxyClient.gd     # WebSocket 클라이언트
│   ├── userManager.gd     # 사용자 관리
│   └── userBase.gd        # 사용자 데이터 구조
├── mainWindow/            # 메인 UI 및 로직
│   ├── mainProcess.gd     # 메인 프로세스
│   ├── userConfig.gd      # 사용자 설정
│   └── mainWindow.tscn    # 메인 UI 씬
├── python_proxy/          # Python 프록시 서버
│   ├── WSProxy.py         # 프록시 서버 메인
│   └── trayicon.png       # 트레이 아이콘
├── project.godot          # Godot 프로젝트 설정
├── LICENSE                # MIT 라이선스
└── icon.png               # 프로젝트 아이콘
```

## 🔌 API 및 통신

### 프록시 서버 WebSocket 메시지 포맷

#### Godot → 프록시 서버

```json
{
  "command": "set_token",
  "access_token": "your_access_token",
  "socket_url": "socket_endpoint_url"
}
```

```json
{
  "command": "connect"
}
```

```json
{
  "command": "disconnect"
}
```

#### 프록시 서버 → Godot

```json
{
  "type": "socket_event",
  "event": "CHAT",
  "data": {
    // 채팅 데이터
  }
}
```

### 치지직 이벤트 타입

- **SYSTEM**: 시스템 메시지 (연결, 구독 등)
- **CHAT**: 채팅 메시지
- **DONATION**: 치즈 후원
- **SUBSCRIPTION**: 정기 구독

## ⚙️ 설정

### 프록시 클라이언트 설정

`class/proxyClient.gd`에서 프록시 서버 주소 변경:

```gdscript
var proxy_url: String = "ws://127.0.0.1:8765/ws"
```

### 화면 설정

`project.godot`에서 창 크기 및 투명도 설정:

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/transparent=true
window/per_pixel_transparency/allowed=true
```

## 🛠️ 개발 및 빌드

### 개발 모드

1. Godot 에디터에서 프로젝트 열기
2. 스크립트 편집 및 씬 수정
3. F5로 즉시 테스트

### 프록시 서버 빌드 (선택사항)

PyInstaller를 사용하여 독립 실행 파일 생성:

```bash
pip install pyinstaller
cd python_proxy
pyinstaller --onefile --windowed --add-data "trayicon.png;." WSProxy.py
```

## 🐛 문제 해결

### 프록시 서버 연결 실패
- 프록시 서버가 실행 중인지 확인
- `config.ini`의 포트 번호와 Godot의 `proxy_url`이 일치하는지 확인
- 방화벽에서 포트가 차단되지 않았는지 확인

### 치지직 연결 실패
- Access Token이 올바른지 확인
- 토큰이 만료되지 않았는지 확인 (필요시 Refresh Token 사용)
- 치지직 API 접속 권한이 있는지 확인

### 캐릭터가 표시되지 않음
- 채팅 메시지가 실제로 수신되는지 로그 확인
- 캐릭터 스프라이트 파일이 모두 존재하는지 확인

### 로그 확인

- **프록시 서버**: `python_proxy/proxy.log` 파일 확인
- **Godot**: 에디터 하단의 "Output" 탭 확인

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

```
MIT License

Copyright (c) 2025 BlacK.CHi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👨‍💻 개발자

**블랙치이 (BlacK.CHi)**
- GitHub: [@BlacK-CHi](https://github.com/BlacK-CHi)
- Twitter: [@BKCHI_shelter](https://twitter.com/BKCHI_shelter)

## 🙏 감사의 말

- [Godot Engine](https://godotengine.org/) - 오픈소스 게임 엔진
- [치지직(CHZZK)](https://chzzk.naver.com/) - 라이브 스트리밍 플랫폼
- [Socket.IO](https://socket.io/) - 실시간 통신 라이브러리

## 🔮 향후 계획

- [ ] 더 많은 캐릭터 스킨 추가
- [ ] 사운드 이펙트 지원
- [ ] 사용자 정의 애니메이션 지원
- [ ] 다국어 지원 (영어, 일본어 등)
- [ ] GUI 기반 설정 편집기
- [ ] 더 많은 이벤트 타입 지원

## 📞 문의 및 기여

이슈나 기능 제안이 있으시면 GitHub Issues를 통해 알려주세요.
Pull Request는 언제나 환영합니다!

---

**즐거운 스트리밍 되세요! 🎉**
