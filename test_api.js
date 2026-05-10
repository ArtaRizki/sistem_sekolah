

async function test() {
  const bodyObj = {"action":"addNilai","nama":"testing","nis":"0","mapel":"PJOK","nilai":88,"sekolah":"MA Al-Ma'arif 2 Plered","tanggal":"2026-05-10"};
  const res = await fetch('https://script.google.com/macros/s/AKfycbwBN4DkmIy4slzlFd703utieZl1RGh8jhrEOkxZ4JbMvnEfH6hp-keA9MApQSahWidZoQ/exec', {
    method: 'POST',
    body: JSON.stringify(bodyObj),
    headers: { 'Content-Type': 'application/json' }
  });
  console.log(await res.text());
}
test();
