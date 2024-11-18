//定義照明按鈕按鈕
const all_background_show = [
    "ABS_BACK01","ABS_BACK02","ABS_BACK03","ABS_BACK04",
    // "ABS_BACK05","ABS_BACK06","ABS_BACK07","ABS_BACK08",
    // "ABS_BACK09","ABS_BACK10","ABS_BACK11","ABS_BACK12",
];

all_background_show.forEach(element => duchamp.getWidgetByName(element).setVisible(false));

duchamp.getWidgetByName('ABS_BACK'+P_EQP).setVisible(true); 