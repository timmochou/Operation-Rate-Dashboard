function(){
    var model = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","CHT_TIME",1,5)');
    var check = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","CHT_TIME",1,9)');
    var stime = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","CHT_TIME",1,18)');
    var etime = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","CHT_TIME",1,19)');

    return "生產機種: "+ model+"</br> 首件檢查: "+check+"</br> 開始時間: "+stime+"</br> 結束時間: "+etime ;

}



////
function(){ 
    var now = new Date();
    var now_sec = now.getHours()*3600+now.getMinutes()*60+now.getSeconds();
    var stime = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","Cht_Produce_Schedule",1,18)');
    var etime = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","Cht_Produce_Schedule",1,19)');
    var model = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","Cht_Produce_Schedule",1,5)');
    var check = FR.remoteEvaluate('=map("'+this.category+this.seriesName+'","Cht_Produce_Schedule",1,9)');
    var color ;
    if(check == '01'){
       color = '#F43636'  }else if (check == '02'){
       color = '#FFEF00'  }else {
       color = '#49B24E'  }
    if(now_sec>=stime && now_sec <=etime){
    return  '<a style="color:'+color+';">'+model+ '</a>';
    } else{return ""}}