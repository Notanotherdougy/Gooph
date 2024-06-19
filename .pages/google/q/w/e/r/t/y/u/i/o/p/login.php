<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top Secret Admin Panel</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
            margin: 0;
            height: 100vh;
            overflow: hidden;
        }

        #secret-trigger {
            width: 100%;
            height: 100vh;
            position: absolute;
            top: 0;
            left: 0;
            cursor: default;
            z-index: 999;
        }

        #hidden-login {
            display: none;
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: white;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
            border-radius: 10px;
            z-index: 1000;
        }

        #hidden-login h2 {
            margin-top: 0;
        }

        #hidden-login input {
            width: 100%;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #ccc;
            border-radius: 5px;
        }

        #hidden-login button {
            width: 100%;
            padding: 10px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }

        #hidden-login button:hover {
            background-color: #0056b3;
        }

        .hidden {
            display: none;
        }
    </style>
</head>
<body>
    <div id="secret-trigger"></div>
    <div id="hidden-login" class="hidden">
        <form id="login-form" action="/admin/login" method="POST">
            <h2>Admin Login</h2>
            <label for="username">Username:</label>
            <input type="text" id="username" name="username" required>
            <label for="password">Password:</label>
            <input type="password" id="password" name="password" required>
            <button type="submit">Login</button>
        </form>
    </div>
    <script>
        let secretCode = [];
        let clickCount = 0;
        const revealCode = ['KeyU', 'KeyP', 'KeyU', 'KeyP'];
        const hiddenLogin = document.getElementById('hidden-login');
        const secretTrigger = document.getElementById('secret-trigger');

        document.addEventListener('keydown', (event) => {
            secretCode.push(event.code);

            if (secretCode.length > revealCode.length) {
                secretCode.shift();
            }

            if (JSON.stringify(secretCode) === JSON.stringify(revealCode) && clickCount >= 5) {
                hiddenLogin.classList.remove('hidden');
                secretCode = [];
                clickCount = 0;
            }
        });

        secretTrigger.addEventListener('click', () => {
            clickCount++;
            if (clickCount > 5) {
                setTimeout(() => { clickCount = 0; }, 5000);
            }
        });
    </script>
</body>
</html>
