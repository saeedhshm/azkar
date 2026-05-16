import json
import os

def update_file(filename, updates):
    with open(filename, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Merge updates
    for key, value in updates.items():
        if key not in data:
            data[key] = {}
        if isinstance(value, dict):
            for k, v in value.items():
                if k not in data[key]:
                    data[key][k] = {}
                if isinstance(v, dict):
                    data[key][k].update(v)
                else:
                    data[key][k] = v
        else:
            data[key] = value

    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

english_updates = {
    "common": {
        "audio": "Audio"
    },
    "home": {
        "greetings": {
            "night": "🌙 Welcome",
            "morning": "🌤️ Good morning",
            "afternoon": "☀️ Good afternoon",
            "evening": "🌅 Good evening",
            "late_night": "🌙 Good night"
        }
    },
    "favorites": {
        "empty_subtitle": "Add your favorite adhkar from the adhkar list by tapping the bookmark icon."
    },
    "settings": {
        "footer": {
            "app_name": "Azkari — Daily Adhkar App",
            "version": "Version {version}"
        }
    }
}

arabic_updates = {
    "common": {
        "audio": "الصوت"
    },
    "home": {
        "greetings": {
            "night": "🌙 مرحباً بك",
            "morning": "🌤️ صباح الخير",
            "afternoon": "☀️ مساء النور",
            "evening": "🌅 مساء الخير",
            "late_night": "🌙 تصبح على خير"
        }
    },
    "favorites": {
        "empty_subtitle": "أضف أذكارك المفضلة من قائمة الأذكار بالضغط على أيقونة الإشارة المرجعية"
    },
    "settings": {
        "footer": {
            "app_name": "أذكاري — تطبيق الأذكار اليومية",
            "version": "الإصدار {version}"
        }
    }
}

turkish_updates = {
    "common": {
        "audio": "Ses"
    },
    "home": {
        "greetings": {
            "night": "🌙 Hoşgeldiniz",
            "morning": "🌤️ Günaydın",
            "afternoon": "☀️ İyi öğleden sonralar",
            "evening": "🌅 İyi akşamlar",
            "late_night": "🌙 İyi geceler"
        }
    },
    "favorites": {
        "empty_subtitle": "Yer imi simgesine dokunarak zikir listesinden favori zikirlerinizi ekleyin."
    },
    "settings": {
        "footer": {
            "app_name": "Azkari — Günlük Zikir Uygulaması",
            "version": "Sürüm {version}"
        }
    }
}

indonesian_updates = {
    "common": {
        "audio": "Audio"
    },
    "home": {
        "greetings": {
            "night": "🌙 Selamat datang",
            "morning": "🌤️ Selamat pagi",
            "afternoon": "☀️ Selamat siang",
            "evening": "🌅 Selamat sore",
            "late_night": "🌙 Selamat malam"
        }
    },
    "favorites": {
        "empty_subtitle": "Tambahkan zikir favorit Anda dari daftar zikir dengan mengetuk ikon simpan."
    },
    "settings": {
        "footer": {
            "app_name": "Azkari — Aplikasi Zikir Harian",
            "version": "Versi {version}"
        }
    }
}

base_path = "assets/translations"
update_file(f"{base_path}/en.json", english_updates)
update_file(f"{base_path}/ar.json", arabic_updates)
update_file(f"{base_path}/tr.json", turkish_updates)
update_file(f"{base_path}/id.json", indonesian_updates)

print("Translations updated!")
