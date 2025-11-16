# GitHub Pages Kurulumu

Bu proje için basit bir tanıtım sitesi oluşturmak üzere repoda `gh-pages/` dizini açıldı. Aşağıdaki adımlarla GitHub Pages üzerinden yayınlayabilirsiniz:

1. **Branch Yapısı**  
   - `gh-pages/` klasöründeki statik dosyalar (şu an `index.html`, `privacy.html` ve `styles.css`) `main` branch'i içinde saklanıyor.  
   - İsterseniz ayrı bir `gh-pages` branch'i açıp yalnız bu klasörü oraya taşıyabilirsiniz.

2. **GitHub Pages Ayarı**  
   - Repo → **Settings → Pages** menüsüne gidin.  
   - *Build and deployment* altında `Deploy from a branch` seçin.  
   - Source: `main`, Folder: `/gh-pages`.  
   - Kaydedin; birkaç dakika içinde site `https://<kullanıcı>.github.io/FormAnaliziAi/` adresinde yayınlanır.

3. **İçerik Güncelleme**  
   - Landing page metinleri `gh-pages/index.html`, gizlilik politikası `gh-pages/privacy.html` ve stiller `gh-pages/styles.css` dosyasında.  
   - Yeni bölüm/asset eklemek için dosyaları düzenleyip `main` branch'ine push etmeniz yeterli.

4. **Opsiyonel: Ayrı Branch**  
   - `git checkout -b gh-pages` ile yeni branch açıp `gh-pages/` klasörünü kök dizine kopyalayabilirsiniz.  
   - Settings → Pages kısmında Source olarak bu branch'i ve `/` klasörünü seçin.

5. **Doğrulama**  
   - Pages sekmesinde build loglarını kontrol edin.  
   - Güncellemeler genelde 1–2 dakika içinde canlıya alınır.

Belirli içerik talepleriniz olursa landing page bileşenleri kolayca genişletilebilir.
