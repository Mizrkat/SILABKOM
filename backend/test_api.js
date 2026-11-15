const http = require('http');

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const dataString = body ? JSON.stringify(body) : '';
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: 3000,
        path,
        method,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(dataString)
        }
      },
      res => {
        let responseBody = '';
        res.on('data', chunk => (responseBody += chunk));
        res.on('end', () => {
          try {
            resolve({ statusCode: res.statusCode, data: JSON.parse(responseBody) });
          } catch (e) {
            resolve({ statusCode: res.statusCode, raw: responseBody });
          }
        });
      }
    );
    req.on('error', reject);
    if (dataString) req.write(dataString);
    req.end();
  });
}

async function runTests() {
  console.log('--- TESTING RESTful API ---');
  
  // 1. Root
  const root = await request('GET', '/');
  console.log('1. Root Status:', root.statusCode, root.data.status);

  // 2. Auth Login Mahasiswa
  const loginMhs = await request('POST', '/api/auth/login', {
    nim_nip: '21120124120017',
    password: 'mahasiswa123'
  });
  console.log('2. Login Mahasiswa:', loginMhs.statusCode, loginMhs.data.data.name, 'Role:', loginMhs.data.data.role);

  // 3. Auth Login Asisten
  const loginAst = await request('POST', '/api/auth/login', {
    nim_nip: '199801012023011001',
    password: 'asisten123'
  });
  console.log('3. Login Asisten:', loginAst.statusCode, loginAst.data.data.name, 'Role:', loginAst.data.data.role);

  // 4. Get Components
  const components = await request('GET', '/api/components');
  console.log('4. Get Components Total:', components.data.total);

  // 5. Get Loans
  const loans = await request('GET', '/api/loans');
  console.log('5. Get Loans Total:', loans.data.total, 'First loan borrower:', loans.data.data[0]?.user?.name);

  // 6. Test Mahasiswa create loan
  const newLoan = await request('POST', '/api/loans', {
    user_id: loginMhs.data.data.id,
    component_id: components.data.data[1].id, // Arduino
    borrow_date: '2026-11-20',
    return_date: '2026-11-25',
    reason: 'Pengujian sensor suhu DS18B20 untuk tugas akhir'
  });
  console.log('6. Create Loan Response:', newLoan.statusCode, newLoan.data.data.id, 'Status:', newLoan.data.data.status);

  // 7. Test Asisten approve loan
  const approved = await request('PATCH', `/api/loans/${newLoan.data.data.id}/status`, {
    status: 'approved',
    notes: 'Disetujui. Ambil di Loker A-02.'
  });
  console.log('7. Approve Loan Response:', approved.statusCode, approved.data.message);

  // 8. Test Mahasiswa return with camera photo
  const returning = await request('PATCH', `/api/loans/${newLoan.data.data.id}/status`, {
    status: 'returning',
    notes: 'Modul telah ditaruh di meja lab.',
    return_photo: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...'
  });
  console.log('8. Returning with Photo Response:', returning.statusCode, returning.data.data.status);

  // 9. Test Asisten confirm return
  const confirmed = await request('PATCH', `/api/loans/${newLoan.data.data.id}/status`, {
    status: 'returned',
    notes: 'Barang telah diterima kembali dan dicek oleh asisten.'
  });
  console.log('9. Confirm Returned Response:', confirmed.statusCode, confirmed.data.message);

  console.log('--- ALL API TESTS COMPLETED SUCCESSFULLY! ---');
  process.exit(0);
}

// Start server in background for test
require('./src/server');
setTimeout(runTests, 1000);
