## 치지직 애플리케이션 등록하기
네이버에 로그인한 후, [치지직 Developers](https://developers.chzzk.naver.com) 에 접속 및 메인 화면의 ``내 서비스`` 버튼을 클릭합니다.

<img width="711" height="329" alt="image" src="https://github.com/user-attachments/assets/850aa14b-a7c0-4a8d-ae11-43cdf6ca355f" />


애플리케이션 목록 페이지에서 ``애플리케이션 등록`` 을 클릭합니다. 등록 페이지의 내용을 아래 표를 참고하여 입력해주세요.

| 구분           | 설정값                                 | 비고                                                                               |
| ------------ | ----------------------------------- | -------------------------------------------------------------------------------- |
| 애플리케이션 ID    | <원하는 대로 입력>                         | naver, chzzk 등 고유명사를 사용할 수 없습니다.                                                 |
| 애플리케이션 이름    | <원하는 대로 입력>                         | naver, chzzk 등 고유명사를 사용할 수 없습니다.                                                 |
| 로그인 리디렉션 URL | ``http://localhost:8080/``          | 프록시 측에서 해당 페이지를 호스팅합니다.                                                          |
| API Scopes   | ``채팅 메시지 조회``, ``후원 조회``, ``구독 조회`` | 각각 채팅, 후원, 구독 이벤트 처리에 필요합니다. v1.1 기준 채팅 메시지만 사용하지만, 추후 후원/구독 이벤트 또한 업데이트될 예정입니다. |


등록 후 표시되는 화면에서 ``클라이언트 ID``, ``클라이언트 Secret``을 안전한 곳에 복사해둡니다. (오버레이 설정에 사용됩니다.)

---

## 캔냥닷치 프록시 시작하기
다운로드받은 캔냥닷치 프록시(``cannyandachi_Proxy_windows(x64/86).exe``) 파일을 실행합니다.
<br> 캔냥닷치 프록시는 별도의 창 없이 작업 표시줄 아이콘으로 실행됩니다.

> [!NOTE]
> 기본적으로 프록시 서버는 ``ws://127.0.0.1:8765/ws/`` 에서 실행됩니다.
> <br>만약 포트 번호나 IP 변경을 원하는 경우, 트레이 아이콘을 우클릭한 다음 '설정 파일 열기' 를 눌러 설정 파일을 연 뒤,
> <br>원하는 IP 주소나 포트를 입력한 후 저장하고, 프록시 프로그램을 다시 실행해주세요.
> <img width="396" height="209" alt="image" src="https://github.com/user-attachments/assets/189b229a-5bd6-4645-b4ec-f6e8f0df93c1" />
>  ```ini
>  [SERVER]
>  host = 127.0.0.1 <-- 해당 열에서 프록시 서버 주소를 바꿀 수 있습니다.
>  port = 8765
>  
>  [LOGGING]
>  file = proxy.log
>  level = INFO
>  ```

<details>
<summary>콘솔에서 직접 실행할 경우 이곳을 참조해주세요.</summary>

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
   python WSProxy.py
   ```
</details>


---

## 캔냥닷치 오버레이 시작하기
> 참고: 원활한 사용을 위해, 오버레이 프로그램은 **프록시를 먼저 실행한 후** 실행해주세요.

깃허브에서 최신 릴리즈를 다운로드받습니다. 다운로드받은 파일을 실행 후 마우스를 창 왼쪽에 가져다대면 설정 패널이 표시됩니다.


최상단의 ``클라이언트 ID`` 와 ``클라이언트 Secret``에 발급받은 ``클라이언트 ID``, ``클라이언트 Secret``을 각각 붙여넣기한 후 ``로그인``을 클릭합니다.
<br> 브라우저에서 네이버 로그인 및 애플리케이션 승인을 마친 후, 리디렉션되는 화면에서 ``인증 키 복사하기`` 버튼을 눌러 인증 키를 복사합니다.
<br><br><img width="321" height="176" alt="image" src="https://github.com/user-attachments/assets/3aea44ac-e4c3-4c91-9b87-59eb4f68550d" /> <img width="auto" height="176" alt="image" src="https://github.com/user-attachments/assets/06ea9ecf-0bb7-46bf-a1c8-ff3e768fe055" />


> [!NOTE]
> ``자동 로그인`` 을 체크하면 입력된 인증 정보를 별도의 파일에 저장하고, 다음 실행 시 브라우저 인증 과정을 자동으로 실행합니다.
> <br>인증 정보를 지우려면 ``자동 로그인`` 체크를 해제하면 인증 정보가 소거됩니다.
> 
> 해당 인증 정보 파일은 **암호화가 되어 있지 않으므로 보안에 각별한 주의를 요합니다.**


복사한 인증 키를 ``인증 키를 입력하세요.`` 필드에 붙여넣기한 후, ``인증`` 버튼을 클릭합니다.
<br>제대로 인증이 진행된 경우 아래의 ``액세스 토큰``, ``갱신 토큰`` 입력란에 자동으로 값이 입력됩니다.
<br><br><img width="320" height="240" alt="image" src="https://github.com/user-attachments/assets/6e852350-0d20-4481-b3bb-1677e38df874" />


``프록시에 접속하기`` 토글을 활성화합니다.
<br>접속이 완료되면 이미지처럼 ``치지직 API에 정상적으로 로그인되었습니다. 즐거운 스트리밍 되세요!`` 라는 알림이 표시되었다가 사라집니다.
<br><br><img width="385" height="401" alt="image" src="https://github.com/user-attachments/assets/c455c449-eb2d-4274-bbc7-4a885d24e996" />


> [!IMPORTANT]
> 기본 아바타가 설정되어 있지 않은 경우 ``기본 아바타가 설정되어 있지 않습니다.`` 알림이 표시됩니다.
> <br>[아바타 관리하기](https://github.com/BlacK-CHi/cannyadachi/blob/main/docs/avatar.md) 문서를 참고하여 아바타를 불러오기 & 기본 아바타 설정 후 재시도해주세요.

