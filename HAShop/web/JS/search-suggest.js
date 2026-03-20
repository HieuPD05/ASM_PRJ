(function () {
  const input = document.getElementById("ssInput");
  const dropdown = document.getElementById("ssDropdown");
  const listBox = document.getElementById("ssList");
  const viewAll = document.getElementById("ssViewAll");

  if (!input || !dropdown || !listBox || !viewAll) return;

  let timer = null;

  function hide() {
    dropdown.style.display = "none";
  }

  function show() {
    dropdown.style.display = "block";
  }

  function money(v) {
    try {
      return Number(v).toLocaleString("vi-VN") + "đ";
    } catch (e) {
      return v + "đ";
    }
  }

  async function fetchSuggest(q) {
    const url = "search-suggest?q=" + encodeURIComponent(q);
    const res = await fetch(url, { method: "GET" });
    if (!res.ok) return { items: [] };
    return await res.json();
  }

  function render(q, items) {
    listBox.innerHTML = "";

    viewAll.href = "index.jsp?module=product&q=" + encodeURIComponent(q);

    if (!items || items.length === 0) {
      listBox.innerHTML = '<div class="ss-empty">Không có kết quả</div>';
      show();
      return;
    }

    items.forEach(it => {
      const a = document.createElement("a");
      a.className = "ss-item";
      a.href = "index.jsp?module=product_detail&id=" + encodeURIComponent(it.id);

      const img = document.createElement("img");
      img.className = "ss-img";
      img.src = (it.thumbnail && it.thumbnail.trim().length > 0) ? it.thumbnail : "images/logo.png";
      img.alt = it.name || "";

      const info = document.createElement("div");
      info.className = "ss-info";

      const name = document.createElement("div");
      name.className = "ss-name";
      name.textContent = it.name || "";

      const price = document.createElement("div");
      price.className = "ss-price";
      price.textContent = money(it.price);

      info.appendChild(name);
      info.appendChild(price);

      a.appendChild(img);
      a.appendChild(info);

      listBox.appendChild(a);
    });

    show();
  }

  input.addEventListener("input", function () {
    const q = input.value.trim();

    if (timer) clearTimeout(timer);

    if (q.length < 1) {
      hide();
      return;
    }

    timer = setTimeout(async () => {
      try {
        const data = await fetchSuggest(q);
        render(q, data.items || []);
      } catch (e) {
        hide();
      }
    }, 200);
  });

  // click ra ngoài thì ẩn
  document.addEventListener("click", function (e) {
    const wrap = document.querySelector(".ss-wrap");
    if (!wrap) return;
    if (!wrap.contains(e.target)) hide();
  });

  // focus lại thì show nếu có nội dung
  input.addEventListener("focus", function () {
    const q = input.value.trim();
    if (q.length >= 1) {
      // nếu đang có content thì show lại
      if (listBox.innerHTML.trim().length > 0) show();
    }
  });
})();
