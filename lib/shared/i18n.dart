// Mirrors src/lib/i18n.ts's { key: { en, id } } dictionary shape — same pattern the web
// app already solved, kept in sync by hand rather than pulling in an ARB/gen-l10n toolchain
// for a project that already has a working home-grown one.
enum AppLocale { en, id }

const Map<String, Map<AppLocale, String>> _strings = {
  'appName': {AppLocale.en: 'Medi-Care HIV', AppLocale.id: 'Medi-Care HIV'},
  'login': {AppLocale.en: 'Log In', AppLocale.id: 'Masuk'},
  'signup': {AppLocale.en: 'Sign Up', AppLocale.id: 'Daftar'},
  'email': {AppLocale.en: 'Email', AppLocale.id: 'Email'},
  'password': {AppLocale.en: 'Password', AppLocale.id: 'Kata Sandi'},
  'name': {AppLocale.en: 'Full Name', AppLocale.id: 'Nama Lengkap'},
  'noAccount': {AppLocale.en: "Don't have an account? Sign up", AppLocale.id: 'Belum punya akun? Daftar'},
  'haveAccount': {AppLocale.en: 'Already have an account? Log in', AppLocale.id: 'Sudah punya akun? Masuk'},
  'signupPending': {
    AppLocale.en: 'Account created. An admin must approve it before you can log in.',
    AppLocale.id: 'Akun dibuat. Admin harus menyetujuinya sebelum Anda dapat masuk.',
  },
  'logout': {AppLocale.en: 'Log Out', AppLocale.id: 'Keluar'},
  'passwordMinLength': {
    AppLocale.en: 'Password must be at least 8 characters',
    AppLocale.id: 'Kata sandi harus minimal 8 karakter',
  },

  // Shared / generic
  'save': {AppLocale.en: 'Save', AppLocale.id: 'Simpan'},
  'cancel': {AppLocale.en: 'Cancel', AppLocale.id: 'Batal'},
  'add': {AppLocale.en: 'Add', AppLocale.id: 'Tambah'},
  'create': {AppLocale.en: 'Create', AppLocale.id: 'Buat'},
  'edit': {AppLocale.en: 'Edit', AppLocale.id: 'Ubah'},
  'delete': {AppLocale.en: 'Delete', AppLocale.id: 'Hapus'},
  'approve': {AppLocale.en: 'Approve', AppLocale.id: 'Setujui'},
  'reject': {AppLocale.en: 'Reject', AppLocale.id: 'Tolak'},
  'active': {AppLocale.en: 'Active', AppLocale.id: 'Aktif'},
  'required': {AppLocale.en: 'Required', AppLocale.id: 'Wajib diisi'},
  'retry': {AppLocale.en: 'Retry', AppLocale.id: 'Coba Lagi'},
  'reports': {AppLocale.en: 'Reports', AppLocale.id: 'Laporan'},
  'noScreeningsYet': {AppLocale.en: 'No screenings yet.', AppLocale.id: 'Belum ada skrining.'},
  'noPatientsYet': {AppLocale.en: 'No patients yet.', AppLocale.id: 'Belum ada pasien.'},
  'patient': {AppLocale.en: 'Patient', AppLocale.id: 'Pasien'},
  'newScreening': {AppLocale.en: 'New Screening', AppLocale.id: 'Skrining Baru'},
  'status': {AppLocale.en: 'Status', AppLocale.id: 'Status'},

  // Bottom nav labels
  'home': {AppLocale.en: 'Home', AppLocale.id: 'Beranda'},
  'screening': {AppLocale.en: 'Screening', AppLocale.id: 'Skrining'},
  'chatTab': {AppLocale.en: 'Chat', AppLocale.id: 'Obrolan'},
  'reminderTab': {AppLocale.en: 'Reminder', AppLocale.id: 'Pengingat'},
  'accountTab': {AppLocale.en: 'Account', AppLocale.id: 'Akun'},
  'consultationsTab': {AppLocale.en: 'Consultations', AppLocale.id: 'Konsultasi'},
  'fullName': {AppLocale.en: 'Full Name', AppLocale.id: 'Nama Lengkap'},
  'fullNameRequired': {AppLocale.en: 'Full Name is required', AppLocale.id: 'Nama Lengkap wajib diisi'},
  'emailRequired': {AppLocale.en: 'Email is required', AppLocale.id: 'Email wajib diisi'},
  'keyRequired': {AppLocale.en: 'Key is required', AppLocale.id: 'Kunci wajib diisi'},

  // Admin — Symptom Rules
  'symptomRules': {AppLocale.en: 'Symptom Rules', AppLocale.id: 'Aturan Gejala'},
  'newSymptomRule': {AppLocale.en: 'New Symptom Rule', AppLocale.id: 'Aturan Gejala Baru'},
  'highRisk': {AppLocale.en: 'High Risk', AppLocale.id: 'Risiko Tinggi'},
  'keyUniqueNoSpaces': {
    AppLocale.en: 'Key (unique, no spaces)',
    AppLocale.id: 'Kunci (unik, tanpa spasi)',
  },
  'label': {AppLocale.en: 'Label', AppLocale.id: 'Label'},

  // Admin — Users
  'users': {AppLocale.en: 'Users', AppLocale.id: 'Pengguna'},
  'editUser': {AppLocale.en: 'Edit User', AppLocale.id: 'Ubah Pengguna'},
  'createAccount': {AppLocale.en: 'Create Account', AppLocale.id: 'Buat Akun'},
  'roleAdmin': {AppLocale.en: 'Admin', AppLocale.id: 'Admin'},
  'roleProvider': {AppLocale.en: 'Provider', AppLocale.id: 'Petugas'},
  'rolePatient': {AppLocale.en: 'Patient', AppLocale.id: 'Pasien'},
  'role': {AppLocale.en: 'Role', AppLocale.id: 'Peran'},
  'atLeast8Chars': {
    AppLocale.en: 'Password must be at least 8 characters',
    AppLocale.id: 'Kata sandi harus minimal 8 karakter',
  },

  // Admin — Screening Questions
  'screeningQuestions': {AppLocale.en: 'Screening Questions', AppLocale.id: 'Pertanyaan Skrining'},
  'newScreeningQuestion': {
    AppLocale.en: 'New Screening Question',
    AppLocale.id: 'Pertanyaan Skrining Baru',
  },
  'addQuestion': {AppLocale.en: 'Add Question', AppLocale.id: 'Tambah Pertanyaan'},
  'domain': {AppLocale.en: 'Domain', AppLocale.id: 'Domain'},
  'questionEnglish': {AppLocale.en: 'Question (English)', AppLocale.id: 'Pertanyaan (Bahasa Inggris)'},
  'questionIndonesian': {
    AppLocale.en: 'Question (Bahasa Indonesia)',
    AppLocale.id: 'Pertanyaan (Bahasa Indonesia)',
  },
  'labelEn': {AppLocale.en: 'Label (EN)', AppLocale.id: 'Label (EN)'},
  'labelId': {AppLocale.en: 'Label (ID)', AppLocale.id: 'Label (ID)'},

  // Admin — Reminders
  'medicationReminders': {AppLocale.en: 'Medication Reminders', AppLocale.id: 'Pengingat Obat'},
  'timesLabel': {
    AppLocale.en: 'Times (e.g. 08:00, 20:00)',
    AppLocale.id: 'Waktu (contoh: 08:00, 20:00)',
  },
  'notesOptional': {AppLocale.en: 'Notes (optional)', AppLocale.id: 'Catatan (opsional)'},
  'reminderFor': {AppLocale.en: 'Reminder —', AppLocale.id: 'Pengingat —'},

  // Admin — Reports
  'exportReportsDesc': {
    AppLocale.en: 'Export patient ID, name, screening date/time, and risk level as a CSV file.',
    AppLocale.id: 'Ekspor ID pasien, nama, tanggal/waktu skrining, dan tingkat risiko sebagai file CSV.',
  },
  'exportToExcel': {AppLocale.en: 'Export to Excel (CSV)', AppLocale.id: 'Ekspor ke Excel (CSV)'},

  // Provider — Home / Consultations
  'liveConsultations': {AppLocale.en: 'Live Consultations', AppLocale.id: 'Konsultasi Langsung'},
  'patientChatsDesc': {
    AppLocale.en: 'Patient chats needing a provider response.',
    AppLocale.id: 'Percakapan pasien yang menunggu respons petugas.',
  },
  'registerPatient': {AppLocale.en: 'Register Patient', AppLocale.id: 'Daftarkan Pasien'},
  'noOpenConsultations': {
    AppLocale.en: 'No open consultations right now.',
    AppLocale.id: 'Tidak ada konsultasi terbuka saat ini.',
  },
  'claim': {AppLocale.en: 'Claim', AppLocale.id: 'Ambil'},
  'markResolved': {AppLocale.en: 'Mark Resolved', AppLocale.id: 'Tandai Selesai'},
  'typeMessage': {AppLocale.en: 'Type a message…', AppLocale.id: 'Ketik pesan…'},

  // Patient — Home
  'needHelpNow': {AppLocale.en: 'Need help now?', AppLocale.id: 'Butuh bantuan sekarang?'},
  'talkToAssistant': {
    AppLocale.en: 'Talk to our AI symptom-triage assistant.',
    AppLocale.id: 'Bicara dengan asisten AI triase gejala kami.',
  },
  'startChat': {AppLocale.en: 'Start Chat', AppLocale.id: 'Mulai Obrolan'},
  'registerAsPatient': {AppLocale.en: 'Register as Patient', AppLocale.id: 'Daftar sebagai Pasien'},
  'screeningHistory': {AppLocale.en: 'Screening History', AppLocale.id: 'Riwayat Skrining'},
  'medicationReminder': {AppLocale.en: 'Medication Reminder', AppLocale.id: 'Pengingat Obat'},
  'surveyExplanation': {
    AppLocale.en:
        'This app uses a two-stage survey: first a Yes/No for each symptom, then a '
        '1–4 severity rating if you answered Yes. Your responses help your care team '
        'spot ARV side effects early.',
    AppLocale.id:
        'Aplikasi ini menggunakan survei dua tahap: pertama Ya/Tidak untuk setiap gejala, '
        'lalu penilaian tingkat keparahan 1–4 jika Anda menjawab Ya. Jawaban Anda membantu '
        'tim perawatan mendeteksi efek samping ARV lebih awal.',
  },

  // Patient — Account
  'account': {AppLocale.en: 'Account', AppLocale.id: 'Akun'},
  'changePassword': {AppLocale.en: 'Change password', AppLocale.id: 'Ubah kata sandi'},
  'currentPassword': {AppLocale.en: 'Current Password', AppLocale.id: 'Kata Sandi Saat Ini'},
  'newPassword': {AppLocale.en: 'New Password', AppLocale.id: 'Kata Sandi Baru'},
  'confirmNewPassword': {
    AppLocale.en: 'Confirm New Password',
    AppLocale.id: 'Konfirmasi Kata Sandi Baru',
  },
  'currentPasswordRequired': {
    AppLocale.en: 'Current password is required',
    AppLocale.id: 'Kata sandi saat ini wajib diisi',
  },
  'newPasswordsDoNotMatch': {
    AppLocale.en: 'New passwords do not match',
    AppLocale.id: 'Kata sandi baru tidak cocok',
  },
  'saved': {AppLocale.en: 'Saved.', AppLocale.id: 'Tersimpan.'},
  'language': {AppLocale.en: 'Language', AppLocale.id: 'Bahasa'},

  // Patient — Chat
  'aiChatbot': {AppLocale.en: 'AI Chatbot', AppLocale.id: 'Chatbot AI'},
  'yesConnectMe': {AppLocale.en: 'Yes, connect me', AppLocale.id: 'Ya, hubungkan saya'},
  'notNow': {AppLocale.en: 'Not now', AppLocale.id: 'Tidak sekarang'},

  // Patient — Registration
  'register': {AppLocale.en: 'Register', AppLocale.id: 'Daftar'},
  'emailOptional': {AppLocale.en: 'Email (optional)', AppLocale.id: 'Email (opsional)'},
  'phoneOptional': {AppLocale.en: 'Phone (optional)', AppLocale.id: 'Telepon (opsional)'},
  'timezoneHint': {
    AppLocale.en: 'Timezone (IANA, e.g. Asia/Jakarta)',
    AppLocale.id: 'Zona Waktu (IANA, contoh: Asia/Jakarta)',
  },
  'timezoneRequired': {AppLocale.en: 'Timezone is required', AppLocale.id: 'Zona waktu wajib diisi'},

  // Patient — Screening / Reminder
  'submitScreening': {AppLocale.en: 'Submit Screening', AppLocale.id: 'Kirim Skrining'},
  'noActiveReminderPatient': {
    AppLocale.en: 'No active reminder set by your provider yet.',
    AppLocale.id: 'Belum ada pengingat aktif dari petugas Anda.',
  },
  'screeningResult': {AppLocale.en: 'Screening Result', AppLocale.id: 'Hasil Skrining'},
  'backToHome': {AppLocale.en: 'Back to Home', AppLocale.id: 'Kembali ke Beranda'},
  'redFlag': {AppLocale.en: 'RED FLAG', AppLocale.id: 'TANDA BAHAYA'},
  'recommendations': {AppLocale.en: 'Recommendations', AppLocale.id: 'Rekomendasi'},
  'domainScores': {AppLocale.en: 'Domain Scores', AppLocale.id: 'Skor Domain'},
  'reminderTimes': {AppLocale.en: 'Reminder Times', AppLocale.id: 'Waktu Pengingat'},
  'notes': {AppLocale.en: 'Notes', AppLocale.id: 'Catatan'},
  'effectiveFrom': {AppLocale.en: 'Effective From', AppLocale.id: 'Berlaku Sejak'},
  'dateOfBirth': {AppLocale.en: 'Date of Birth', AppLocale.id: 'Tanggal Lahir'},
  'dateOfBirthRequired': {
    AppLocale.en: 'Date of birth is required',
    AppLocale.id: 'Tanggal lahir wajib diisi',
  },
  'chatEnded': {AppLocale.en: 'This chat has ended.', AppLocale.id: 'Obrolan ini telah berakhir.'},
  'pendingRejected': {AppLocale.en: 'Pending / Rejected', AppLocale.id: 'Menunggu / Ditolak'},
  'approved': {AppLocale.en: 'Approved', AppLocale.id: 'Disetujui'},
  'noUsersYet': {AppLocale.en: 'No users yet.', AppLocale.id: 'Belum ada pengguna.'},
  'noScreeningQuestionsYet': {
    AppLocale.en: 'No screening questions yet.',
    AppLocale.id: 'Belum ada pertanyaan skrining.',
  },
  'domainRequired': {AppLocale.en: 'Domain is required', AppLocale.id: 'Domain wajib diisi'},
  'severityOptions1to4': {
    AppLocale.en: 'Severity 1-4 options',
    AppLocale.id: 'Pilihan keparahan 1-4',
  },
  'reminderTimesRequired': {
    AppLocale.en: 'Reminder times are required',
    AppLocale.id: 'Waktu pengingat wajib diisi',
  },
  'effectiveFromOptional': {
    AppLocale.en: 'Effective From (optional)',
    AppLocale.id: 'Berlaku Sejak (opsional)',
  },
  'back': {AppLocale.en: 'Back', AppLocale.id: 'Kembali'},
  'next': {AppLocale.en: 'Next', AppLocale.id: 'Lanjut'},

  // Landing (public, pre-auth) — mirrors HIV-Project-Web's src/app/page.tsx copy exactly,
  // condensed to a single-scroll mobile layout (hero + value props + CTAs, no separate
  // "how it works"/privacy sections — those stay web-only, this is a lighter distillation).
  'landingSignIn': {AppLocale.en: 'Sign in', AppLocale.id: 'Masuk'},
  'landingCreateAccount': {AppLocale.en: 'Create account', AppLocale.id: 'Buat akun'},
  'landingHeadline': {AppLocale.en: 'Your care team, always on.', AppLocale.id: 'Tim perawatan Anda, selalu siap.'},
  'landingSubtext': {
    AppLocale.en:
        'Two-stage symptom screening, real-time provider chat, and medication reminders in '
        'one private platform built for people living with HIV.',
    AppLocale.id:
        'Skrining gejala dua tahap, obrolan langsung dengan petugas, dan pengingat obat '
        'dalam satu platform pribadi yang dibuat untuk orang dengan HIV.',
  },
  'landingU2UInfo': {
    AppLocale.en:
        'With consistent ART, HIV is a manageable condition. An undetectable viral load also '
        'means the virus cannot be sexually transmitted, a fact doctors call U=U '
        '(Undetectable = Untransmittable).',
    AppLocale.id:
        'Dengan ART yang konsisten, HIV adalah kondisi yang dapat dikendalikan. Viral load '
        'yang tidak terdeteksi juga berarti virus tidak dapat ditularkan secara seksual, hal '
        'yang oleh dokter disebut U=U (Undetectable = Untransmittable).',
  },
  'landingValueScreening': {
    AppLocale.en: '6-domain clinical screening model',
    AppLocale.id: 'Model skrining klinis 6 domain',
  },
  'landingValueAssistant': {
    AppLocale.en: 'Assistant triage, real providers behind it',
    AppLocale.id: 'Triase oleh asisten, ditangani petugas sungguhan',
  },
  'landingValuePrivate': {
    AppLocale.en: 'Private by default, visible only to your care team',
    AppLocale.id: 'Privat secara default, hanya terlihat oleh tim perawatan Anda',
  },
  'landingFooterTagline': {
    AppLocale.en: 'Clinical decision support for ART care. Not a substitute for emergency services.',
    AppLocale.id: 'Dukungan keputusan klinis untuk perawatan ART. Bukan pengganti layanan darurat.',
  },
  'areYouSure': {AppLocale.en: 'Are you sure?', AppLocale.id: 'Apakah Anda yakin?'},
  'logoutConfirmMessage': {
    AppLocale.en: 'Are you sure you want to log out?',
    AppLocale.id: 'Apakah Anda yakin ingin keluar?',
  },
  'deleteAccountConfirmMessage': {
    AppLocale.en: 'This will permanently delete the account. This cannot be undone.',
    AppLocale.id: 'Ini akan menghapus akun secara permanen. Tindakan ini tidak dapat dibatalkan.',
  },
  'deleteQuestionConfirmMessage': {
    AppLocale.en: 'This will permanently delete the question. This cannot be undone.',
    AppLocale.id: 'Ini akan menghapus pertanyaan secara permanen. Tindakan ini tidak dapat dibatalkan.',
  },
  'rejectConfirmMessage': {
    AppLocale.en: 'Reject this consultation request?',
    AppLocale.id: 'Tolak permintaan konsultasi ini?',
  },
};

class AppStrings {
  static AppLocale locale = AppLocale.id;
  static String t(String key) => _strings[key]?[locale] ?? key;

  static String greeting(String name) =>
      locale == AppLocale.id ? 'Hai, $name' : 'Hi, $name';

  static String assistantSuggestsProvider(String urgency) => locale == AppLocale.id
      ? 'Asisten menyarankan Anda berbicara dengan petugas ($urgency).'
      : 'The assistant suggests talking to a provider ($urgency).';

  static String escalatedToConsultation(int id) => locale == AppLocale.id
      ? 'Ditingkatkan ke konsultasi langsung (#$id) — petugas akan merespons di sana.'
      : 'Escalated to a live consultation (#$id) — a provider will respond there.';
}
