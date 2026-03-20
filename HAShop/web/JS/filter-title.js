const brandCheckboxes = document.querySelectorAll('.brand-filter');
const title = document.getElementById('categoryTitle');

brandCheckboxes.forEach(cb => {
    cb.addEventListener('change', () => {
        const selected = Array.from(brandCheckboxes)
                .filter(item => item.checked)
                .map(item => item.value);

        title.textContent = selected.length === 0
                ? 'Giày cầu lông'
                : 'Giày cầu lông ' + selected[0];
    });
});
