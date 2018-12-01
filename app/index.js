const fs = require('fs');
const path = require('path');
const child_process = require('child_process');
const electron = require('electron');
const pkg = require('./package.json');

const { app, Tray, Menu, shell } = electron;

let server;
let tray;

if (process.platform === 'darwin') {
  app.dock.hide();
}

const ASSETS_PATH = path.join(__dirname, 'assets');
const VENDOR_PATH = app.isPackaged
  ? path.join(process.resourcesPath, '../Vendor')
  : path.join(__dirname, 'vendor');
const REDIS_PATH = path.join(VENDOR_PATH, 'redis');
const REDIS_SERVER_PATH = path.join(REDIS_PATH, 'bin/redis-server');
const REDIS_CONFIG_PATH = path.join(REDIS_PATH, 'redis.conf');
const USER_DATA_PATH = app.getPath('userData');
const DATA_PATH = path.join(USER_DATA_PATH, 'data');
const LOG_FILE_PATH = path.join(USER_DATA_PATH, 'redis.log');
const CONFIG_FILE_PATH = path.join(USER_DATA_PATH, 'redis.conf');

if (!fs.existsSync(DATA_PATH)) {
  fs.mkdirSync(DATA_PATH);
}

if (!fs.existsSync(CONFIG_FILE_PATH)) {
  fs.copyFileSync(REDIS_CONFIG_PATH, CONFIG_FILE_PATH);
}

const CONFIG_FILE_CONTENTS = fs.readFileSync(CONFIG_FILE_PATH, 'utf8');
const SERVER_PORT = CONFIG_FILE_CONTENTS.match(/^(?:port) (\d+)$/m)[1];

function startServer() {
  server = child_process.spawn(REDIS_SERVER_PATH, [
    CONFIG_FILE_PATH,
    '--dir',
    DATA_PATH,
    '--logfile',
    LOG_FILE_PATH
  ]);

  server.stdout.setEncoding('utf8');
  server.stdout.on('data', (data) => {
    console.log(data);
  });

  server.stderr.setEncoding('utf8');
  server.stderr.on('data', (data) => {
    console.error(data);
  });
}

function stopServer() {
  server.kill();
}

function openDocumentation() {
  shell.openExternal('https://github.com/jpadilla/redisapp');
}

function createTrayMenu() {
  let menu = Menu.buildFromTemplate([
    {
      label: `Redis v${pkg.version}`,
      enabled: false
    },
    {
      label: `Running on port ${SERVER_PORT}`,
      enabled: false
    },
    {
      type: 'separator'
    },
    {
      label: 'Open redis-cli'
    },
    {
      label: 'Open logs directory'
    },
    {
      type: 'separator'
    },
    {
      label: 'Check for updates...'
    },
    {
      label: 'About'
    },
    {
      label: 'Documentation',
      click: openDocumentation
    },
    {
      type: 'separator'
    },
    {
      label: 'Quit',
      click: app.quit
    }
  ]);

  return menu;
}

app.on('ready', () => {
  tray = new Tray(path.join(ASSETS_PATH, 'img', 'iconTemplate.png'));
  tray.setPressedImage(path.join(ASSETS_PATH, 'img', 'iconHighlight.png'));

  startServer();
  let menu = createTrayMenu();
  tray.setContextMenu(menu);
});

app.on('quit', () => {
  try {
    stopServer();
  } catch (err) {
    console.log(err);
  }
});

process.on('uncaughtException', console.error);
