<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top Secret Admin Console</title>
    <style>
        body {
            font-family: 'Courier New', Courier, monospace;
            background-color: #000;
            color: #0f0;
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow: hidden;
        }

        #console {
            width: 90%;
            max-width: 600px;
            height: 90%;
            max-height: 400px;
            background-color: #000;
            border: 1px solid #0f0;
            padding: 10px;
            box-shadow: 0 0 10px #0f0;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
        }

        #hidden-login {
            display: none;
            flex-direction: column;
            align-items: center;
            background-color: #111;
            padding: 20px;
            border: 1px solid #0f0;
            box-shadow: 0 0 10px #0f0;
            border-radius: 10px;
        }

        #hidden-login input {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #0f0;
            background-color: #000;
            color: #0f0;
        }

        #hidden-login button {
            width: 100%;
            padding: 10px;
            background-color: #0f0;
            color: #000;
            border: none;
            cursor: pointer;
        }

        #console p {
            margin: 0;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div id="console">
        <div id="hidden-login" class="hidden">
            <form id="login-form" action="/admin/login" method="POST">
                <input type="text" id="username" name="username" placeholder="Username" required>
                <input type="password" id="password" name="password" placeholder="Password" required>
                <button type="submit">Login</button>
            </form>
        </div>
    </div>
    <script>
        let secretCode = [];
        let clickCount = 0;
        const revealCode = ['KeyR', 'KeyE', 'KeyV', 'KeyE', 'KeyA', 'KeyL'];
        const hiddenLogin = document.getElementById('hidden-login');
        const consoleDiv = document.getElementById('console');

        document.addEventListener('keydown', (event) => {
            secretCode.push(event.code);
            consoleDiv.innerHTML += `<p>${event.code}</p>`;

            if (secretCode.length > revealCode.length) {
                secretCode.shift();
            }

            if (JSON.stringify(secretCode) === JSON.stringify(revealCode) && clickCount >= 3) {
                hiddenLogin.style.display = 'flex';
                secretCode = [];
                clickCount = 0;
            }
        });

        consoleDiv.addEventListener('click', () => {
            clickCount++;
            if (clickCount > 3) {
                setTimeout(() => { clickCount = 0; }, 3000);
            }
        });
    </script>
</body>
</html>
