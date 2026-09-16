*1. Product Owner*
* Bertugas menetapkan toleransi risiko dan kebutuhan bisnis dari aplikasi yang akan dibuat.
* Bertanggung jawab untuk mengonsep bentuk *dashboard* Decision Support System (DSS) yang akan dibangun beserta batasan-batasannya.
* Membuat dan menyusun dokumen perencanaan (dokumen *plan*) di tahap awal.
* Memberikan instruksi kerja atau *assign task* kepada anggota tim lainnya (seperti Developer dan Security Engineer) berdasarkan batasan aplikasi yang telah ditentukan.

*2. Security Engineer*
* Bertugas mengembangkan model ancaman (*threat modeling*) dan aturan kebijakan keamanan (*policy*) berdasarkan konsep *dashboard* dari Product Owner.
* Menganalisis potensi ancaman yang mungkin terjadi pada aplikasi, misalnya mencari celah kemungkinan terjadinya kebocoran data (*data breach*).
* Membuat dokumen *threat modeling* secara bertahap (misalnya versi 1, dan direvisi ke versi 2 jika ada perubahan rencana) dan melakukan *commit* dokumen tersebut ke dalam repositori.

*3. Developer*
* Bertugas melakukan *coding* untuk membangun *dashboard* dengan menerapkan praktik *secure coding*.
* Memastikan kode yang ditulis aman dan meminimalkan celah keamanan (seperti injeksi SQL) berdasarkan panduan ancaman dari *Security Engineer*.
* Memperbaiki temuan kerentanan (vulnerability) yang muncul saat proses pengujian atau *scanning*.
* Menyediakan *Software Bill of Materials* (SBOM) yang menunjukkan kebutuhan platform dari perangkat lunak yang dibuatnya.

*4. Platform/Infrastructure Engineer (Tim Operasional)*
* Bertugas menyediakan infrastruktur dan *platform* (misalnya menyiapkan *Docker*, VPS, atau *environment* lainnya) untuk menjalankan aplikasi.
* Menyiapkan tata kelola dan aturan untuk operasional (*policy admission*), seperti mengatur *database admin*, konfigurasi jaringan, serta *router*.
* Menjalankan *deployment* tanpa memiliki hak untuk merubah-rubah konfigurasi aplikasi atau kode yang sudah dibuat oleh *Developer*.