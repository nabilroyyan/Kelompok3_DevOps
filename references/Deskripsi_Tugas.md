Deskripsi Umum Tugas
* Tugas ini dikerjakan secara berkelompok yang masing-masing terdiri dari tiga orang.
* Tujuan utama proyek ini adalah membangun sebuah *dashboard Decision Support System* (DSS), bukan aplikasi web transaksional yang rumit.
* Fokus utama penilaian bukanlah sekadar pada hasil akhir aplikasi, melainkan pada bagaimana Anda menerapkan proses dan budaya *DevSecOps* (pengembangan, keamanan, dan operasional) secara terstruktur.

Pembagian Peran (Roleplay Tim)
* Langkah pertama yang harus dilakukan adalah menentukan tata kelola dan membagi peran layaknya simulasi tim profesional.
* Peran yang harus ada mencakup *Product Owner*, *Developer*, *Security Engineer*, dan peran infrastruktur/operasional.
* Karena anggota kelompok hanya tiga orang, satu orang dapat merangkap peran, namun tanggung jawab tiap peran harus dijalankan dan terlihat jelas.

Langkah-Langkah Pengerjaan
1. **Tahap Perencanaan:** Mahasiswa yang berperan sebagai *Product Owner* bertugas membuat konsep *dashboard* beserta batasan-batasannya di dalam sebuah dokumen perencanaan.
2. **Pemodelan Ancaman (*Threat Modeling*):** Berdasarkan rencana tersebut, *Security Engineer* harus menyusun *threat modeling* untuk menganalisis potensi ancaman dan risiko keamanan pada *dashboard* yang akan dibuat.
3. **Pengembangan dan *Secure Coding*:** *Developer* mulai menulis kode dengan menerapkan standar keamanan teknis (seperti menggunakan pedoman keamanan OWASP).
4. **Manajemen Repositori:** Kelompok harus membuat repositori Git khusus untuk proyek ini. Struktur *folder* harus mencerminkan artefak proses DevSecOps, seperti *folder* untuk aplikasi, *keys*, kebijakan (*policy*), laporan hasil *scan*, dan *Software Bill of Materials* (SBOM).
5. **Penyediaan Infrastruktur:** Untuk *deployment*, mahasiswa bisa memanfaatkan *homelab*, fasilitas lab kampus (dengan izin), atau layanan VPS/Cloud gratis seperti GitHub *student pack* atau Azure.

Format Pengumpulan dan Evaluasi (UTS)
* **Akses Repositori:** Kelompok wajib mengundang dosen ke dalam repositori GitHub dan *Docker registry* proyek tersebut. Dosen akan memantau *commit* yang masuk untuk menilai keaktifan, rekam jejak, dan kontribusi nyata dari setiap peran.
* **Pengumpulan Laporan:** Laporan diunggah ke *platform* Etol dalam format PDF, dan juga didokumentasikan di dalam GitHub (misalnya menggunakan format *Markdown*).
* **Presentasi UTS:** UTS tidak berupa ujian tertulis, melainkan presentasi proyek.
* Setiap kelompok diberikan waktu sekitar 15 menit untuk melakukan presentasi secara luring (direncanakan pada hari Jumat siang).
* Saat presentasi, mahasiswa harus memaparkan peran masing-masing, menjelaskan setiap tahapan proses yang dilalui, serta menunjukkan artefak keamanan dan dokumen yang dihasilkan.