const fs = require('fs');
const path = require('path');

const mode = process.argv[2] ? process.argv[2].toLowerCase() : 'prod';

const VPS_IP = '202.6.239.231';
const PROD_API = 'https://helpdesk2.mra.co.id/api';
const DEV_API = 'http://10.0.2.2:5000/api'; // IP gateway default emulator Android

let targetApi = PROD_API;
let activeMode = 'PRODUCTION';

if (mode === 'dev' || mode === 'development') {
  targetApi = DEV_API;
  activeMode = 'DEVELOPMENT (LOCAL)';
}

const configContent = `// GENERATED FILE - DO NOT EDIT MANUALLY
class AppConfig {
  static const String apiUrl = '${targetApi}';
  static const String vpsIp = '${VPS_IP}';
}
`;

const configPath = path.join(__dirname, 'lib', 'config.dart');

try {
  fs.writeFileSync(configPath, configContent, 'utf8');
  console.log('==================================================');
  console.log(' MRA Helpdesk Mobile Environment Configurator');
  console.log('==================================================');
  console.log(` VPS IP Address     : ${VPS_IP}`);
  console.log(` Active Mode        : ${activeMode}`);
  console.log(` Target API Address : ${targetApi}`);
  console.log('--------------------------------------------------');
  console.log(`✓ Berhasil menulis konfigurasi ke: ${configPath}`);
  console.log('==================================================');
} catch (err) {
  console.error('Error saat menulis file konfigurasi:', err);
}
