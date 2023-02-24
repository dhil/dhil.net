function formatDate(datetime) {
    const d = new Date(datetime);
    const months = [ "January", "February"
                    , "March", "April", "May"
                    , "June", "July", "August"
                    , "September", "October", "November"
                    ,"December" ];
    return months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
}

function updateDateField(nodeId) {
    const node = document.getElementById(nodeId);
    node.innerText = formatDate(node.innerText);
}

document.addEventListener("DOMContentLoaded", function() {
    updateDateField("last-modified");
});
