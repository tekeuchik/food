
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import java.util.Collections;  //Collectionsを使うための宣言

Capture cam;
MultiMarker nya;
SecondApplet second; //複数ウィンドウ
Range range;
CombinationImage combination_image;
DisplaceImage displace_image;
MultipleDisplay multiple_display;

final int FOODNUM = 78; //食べ物の数(初めの0,1番目の分だけ増えている
final int MAXCOM = 18; //表示する成分の数
final int IMG_W = 640; //640→800
final int IMG_H = 480; //480→600
final int marker_size = 30;
final float RECOMMENDED_AMOUNT_PROTEIN = 60.0; //たんぱく質
final float RECOMMENDED_AMOUNT_LIPID = 65.0; //脂質
final float RECOMMENDED_AMOUNT_CARBOHYDRATE = 338.0; //炭水化物
final int SEASONING_FIRST = 7;
final int SEASONING_LAST = 11;

Table table;  //食品のtable
Table name_standard_table;
PImage img[];//画像を格納する配列
PImage dish;  //皿の画像
String loadcsv[];  //csvファイルを読み込む
String composition[]; //成分の日本名をコンマごとに区切ったものを格納した配列
PFont font;
float total[] = new float[MAXCOM];  //総栄養素
float markpoint[][] = new float[FOODNUM][8];  //[マーカのid][左上のx,y座標]を格納
float midpoint[][] = new float[FOODNUM][2];  //中点のx,y座標
int id_num;  //グローバルの変数でbeginTransformの引数とする
boolean total_output_flag = false;  //総栄養素の出力を表示させるflag
float gram[] = new float[FOODNUM];  //画像あたりのグラム数を格納
float original_gram[] = new float[FOODNUM]; //元のグラム数を格納
int timer = 0;
float plus_array[] = new float[FOODNUM];  //増加配列
String string_dish_flag[] =new String[FOODNUM];
boolean dish_flag[] = new boolean[FOODNUM];
int evo_array[] = new int[FOODNUM];
int plus_limit[] = new int[FOODNUM];  //増加の限界
float standard_nutrition[][] = new float[3][MAXCOM];   //man,woman,kidsの基準栄養素
boolean gram_flag = false;
int gram_id;  //gramを示したいマーカid
boolean poker_flag = false;
boolean random_flag = true;  //ランダムを行うフラグ
int poker_id = 0;  //pokerで使うためのid
int size_factor[] = new int[FOODNUM];
boolean mouse_flag = false;
int dragged_id;  //draggedされているid
boolean dragged_flag;
int released_x, released_y;  //draggedされた座標
int released_position[][] = new int[FOODNUM][2];  //ドロップされたidの座標を格納
ArrayList<Integer> released_id_array = new ArrayList<Integer>();  //ドロップされたidを格納
int page_num = 1;  //mouseモードの表示ページ数
int max_page = 1;  //mouseモードのmax表示ページ数
boolean trash_flag = false;  //mouseモード時にプレスされてる間true
PImage one_meal, three_meal;
PImage man, woman, kids;
PImage poker;
PImage left, right;
PImage reload;
PImage mouse;
PImage page_left, page_right;
PImage tray;
PImage trash;
int released_array_size = 0;
boolean spoon_color[] = new boolean[FOODNUM];  //trueのとき大さじ、falseのとき小さじを表す
boolean pressed_flag = false;
int tab_num = 0;
int tab_array[][] = new int[6][FOODNUM];  //タブごとに食品のidを格納
int tab0_i, tab1_i, tab2_i, tab3_i, tab4_i, tab5_i = 0;  //tab_numごとのインクリメント変数
float tab_array_size = 0;
PImage rice_icon, food_icon, vegetable_icon, fruit_icon, egg_icon, salt_icon;
int r, g, b = 0;
String jap_name[] = new String[FOODNUM];  //大さじまでのidを引いた日本名を格納

void settings() {
  size(640, 480, P3D); //P3D→3D空間であることを明示
}

void setup() { //初期化
  second = new SecondApplet(this);  //もう一つのウィンドウのインスタンス化
  range = new Range();
  combination_image = new CombinationImage();
  displace_image = new DisplaceImage();
  multiple_display = new MultipleDisplay();
  colorMode(RGB, 256); //R,G,Bを各256段階で指定
  textFont(createFont("HGPKagoji", 36)); //フォントを指定
  //println(MultiMarker.VERSION);
  cam = new Capture(this, IMG_W, IMG_H, "Logicool HD Webcam C510");
  cam = new Capture(this, IMG_W, IMG_H); //Captureクラスのインスタンス
  nya = new MultiMarker(this, IMG_W, IMG_H, "camera_para.dat", NyAR4PsgConfig. CONFIG_PSG); //サイズ変更時width, IMG_H
  img = new PImage[FOODNUM];

  table = loadTable("food_composition.csv", "header");  //tableの読み込み
  name_standard_table = loadTable("composition_name.csv", "header");
  loadcsv = loadStrings("composition_name.csv");  //成分の読み込み
  composition = split(loadcsv[0], ',');  //コンマ区切りで成分の日本名をcompositionに格納
  dish = loadImage("dish.png");
  one_meal = loadImage("one_meal.png");
  three_meal = loadImage("three_meal.png");
  man = loadImage("man.png");
  woman = loadImage("woman.png");
  kids = loadImage("kids.png");
  poker = loadImage("poker.png");
  left = loadImage("left.png");
  right = loadImage("right.png");
  reload = loadImage("reload.png");
  mouse = loadImage("mouse.png");
  page_left = loadImage("page_left.png");
  page_right = loadImage("page_right.png");
  tray = loadImage("tray.png");
  trash = loadImage("trash.png");

  rice_icon = loadImage("rice_icon.png");
  food_icon = loadImage("food_icon.png");
  vegetable_icon = loadImage("vegetable_icon.png");
  fruit_icon = loadImage("fruit_icon.png");
  egg_icon = loadImage("egg_icon.png");
  salt_icon = loadImage("salt_icon.png");

  frameRate(10); //1秒間に10回画面を更新
  for (int i=0; i<2; i++) {
    nya.addNyIdMarker(i,marker_size); //対象のNyIDを登録
  }
  for (int i=0; i<FOODNUM; i++) { //FOODNUM：食べ物の数(78)
    if (i >= 5 && i <= SEASONING_LAST) {
      if (i == 6) {
        plus_array[i] = 1.5;
        spoon_color[i] = true;
      }
      else {
        plus_array[i] = 0.5;
      }
    }
    else {
      plus_array[i] = 1;
    }
  }
  for (TableRow row : table.rows()) { //Tableクラス：CSVやTSVを扱える命令
    int marker_id = row.getInt("marker_id");
    nya.addNyIdMarker(marker_id, marker_size);
    img[marker_id] = loadImage(row.getString("eng_name")+".png");
    jap_name[marker_id] = row.getString("jap_name");
    original_gram[marker_id] = row.getFloat("gram");
    string_dish_flag[marker_id] = row.getString("dish_flag");
    dish_flag[marker_id] = boolean(string_dish_flag[marker_id]);
    evo_array[marker_id] = row.getInt("evo_id");
    plus_limit[marker_id] = row.getInt("plus_limit");
    size_factor[marker_id] = row.getInt("size_factor");
    int table_tab_num = row.getInt("tab_num");
    for (int j=0; j < 6; j++) {
      if (j == table_tab_num) {
        if (j == 0) {
          tab_array[j][tab0_i] = marker_id;
          tab0_i++;
        }
        else if (j == 1) {
          tab_array[j][tab1_i] = marker_id;
          tab1_i++;
        }
        else if (j == 2) {
          tab_array[j][tab2_i] = marker_id;
          tab2_i++;
        }
        else if (j == 3) {
          tab_array[j][tab3_i] = marker_id;
          tab3_i++;
        }
        else if (j == 4) {
          tab_array[j][tab4_i] = marker_id;
          tab4_i++;
        }
        else if (j == 5) {
          tab_array[j][tab5_i] = marker_id;
          tab5_i++;
        }
        break;
      }
    }
  }
  tab_array_size = tab0_i;  //tab_array_size初期値をtab0のサイズにあわせておく
  max_page = ceil(tab_array_size / 8); //ceil()：値を切り上げる

  //栄養摂取基準値を配列に格納
  int line_spacing = 0;
  for (TableRow row : name_standard_table.rows()) {
      for (int i=0; i<MAXCOM; i++) {
        standard_nutrition[line_spacing][i] = row.getFloat(composition[i]);
      }
    line_spacing++;
  }
  textAlign(CENTER); //文字列指定

  cam.start();
}

void draw() { //繰り返し実行
  timer++;
  if (poker_flag == false
  && mouse_flag == false) {
    for (int i=0; i<MAXCOM; i++) {
      total[i] = 0;
    }
    for (int i=0; i<FOODNUM; i++) {
      gram[i] = original_gram[i];
    }

    if (cam.available() != true) { //カメラが利用できない場合
      return; //何もせずに返す
    }
    cam.read(); //映像を読み込む
    nya.detect(cam); //detect関数で、映像からマーカを検出
    background(0); //黒
    image(cam, 0, 0, IMG_W, IMG_H);  //サイズ変更時
    for (id_num=0; id_num<FOODNUM; id_num++) {
      if ((!nya.isExist(id_num))) {
        for (int i=0; i<8; i++) {
          markpoint[id_num][i] = 0; //markpoint：マーカの左上のx,y座標を格納
        }
        for (int i=0; i<2; i++) {
          midpoint[id_num][i] = 0; //midpoint：中点のx,y座標
        }
        continue;
      }

      markpoint[id_num][0] = nya.getMarkerVertex2D(id_num)[0].x;  //画像のマーカの左上のx座標
      markpoint[id_num][1] = nya.getMarkerVertex2D(id_num)[0].y;  //画像のマーカの左上のy座標
      markpoint[id_num][2] = nya.getMarkerVertex2D(id_num)[1].x;  //マーカの右上のx座標
      markpoint[id_num][3] = nya.getMarkerVertex2D(id_num)[1].y;  //マーカの右上のy座標
      markpoint[id_num][4] = nya.getMarkerVertex2D(id_num)[2].x;  //マーカの右下のx座標
      markpoint[id_num][5] = nya.getMarkerVertex2D(id_num)[2].y;  //マーカの右下のy座標
      markpoint[id_num][6] = nya.getMarkerVertex2D(id_num)[3].x;  //マーカの左下のx座標
      markpoint[id_num][7] = nya.getMarkerVertex2D(id_num)[3].y;  //マーカの左下のy座標
      midpoint[id_num][0] = (markpoint[id_num][2]-markpoint[id_num][0])/2 + markpoint[id_num][0];  //中点のx座標
      midpoint[id_num][1] = (markpoint[id_num][5]-markpoint[id_num][3])/2 + markpoint[id_num][3];  //中点のy座標

      // プログラム変更 マーカ中央表示→画面中央表示
      if (id_num < 27) {
        image(img[id_num],IMG_W/5,IMG_H/5,150,150);
      }

      if (id_num == 27 || id_num == 28 || id_num == 29) {
        image(img[id_num],IMG_W/3,IMG_H/3,300,300);
      }

      if (id_num > 29 && id_num < 50) {
        image(img[id_num],IMG_W/5,IMG_H/5,150,150);
      }

      if (id_num >= 50 && id_num <= 64) {
        image(img[id_num],IMG_W/3,IMG_H/3,300,300);
      }

      if (id_num > 64 && id_num <= 70) {
        image(img[id_num],IMG_W/5,IMG_H/5,150,150);
      }

      if (id_num > 70) {
        image(img[id_num],IMG_W/3,IMG_H/3,300,300);
      }

      nya.beginTransform(id_num); //座標投影開始
      //imageMode(CENTER); //表示位置の指定 CENTER→CORNERS
      //resetマーカの認識
      if (id_num == 2) {
        image(img[2], 0, 0, marker_size, marker_size);
        for (int i=0; i<FOODNUM; i++) {
          if (i >= 5 && i <= SEASONING_LAST) {
            if (i == 6) {
              plus_array[i] = 1.5;
              spoon_color[i] = true;
            }
            else {
              plus_array[i] = 0.5;
            }
          }
          else {
            plus_array[i] = 1;
          }
        }
        nya.endTransform();
        break;
      }
      for (TableRow row : table.rows()) {
        int marker_id = row.getInt("marker_id");
        if (id_num == marker_id) {
          scale(-1, -1);  //画像表示の上下左右反転を直すため
          //総栄養素の計算
          for (int i=0; i<MAXCOM; i++) {
            total[i] += row.getFloat(composition[i]) * gram[id_num] / 100 * (plus_array[id_num]);  //+1されているのは、初期状態でplus_arrayは0であるから
          }
          gram[id_num] *= (plus_array[id_num]);
        }
      }
      range.identify_threshold();
      nya.endTransform();
    }
    total_output_flag = true;
  }
  //pokerモード
  else if (poker_flag == true) {
    if (cam.available() != true) {
      return;
    }
    cam.read();
    nya.detect(cam);
    background(0);
    image(cam, 0, 0, IMG_W, IMG_H);
    for (id_num=0; id_num<FOODNUM; id_num++) {
      if ((!nya.isExist(id_num))) {
        continue;
      }
      poker_id = id_num;
      nya.beginTransform(id_num);
      scale(-1, -1);
      imageMode(CENTER);
      image(img[id_num], 0, 0, marker_size*size_factor[id_num], marker_size*size_factor[id_num]);
      nya.endTransform();
    }
  }
  //mouseモード
  else if (mouse_flag == true) {
    println(mouseX, mouseY);
    if (released_array_size > 0) {
      println("released_id_array = " + released_id_array);
    }
    else {
      println("EMPTY");
    }

    background(254, 223, 255);
    noStroke();
    fill(240, 223, 0);//黄色
    rect(400, 0, 40, 40);
    fill(245, 148, 109); //赤
    rect(440, 0, 40, 40);
    fill(135, 239, 56);  //緑
    rect(480, 0, 40, 40);
    fill(250, 220, 170); //クリーム
    rect(520, 0, 40, 40);
    fill(12, 211, 231);//青
    rect(560, 0, 40, 40);
    fill(249, 189, 71); //茶
    rect(600, 0, 40, 40);
    imageMode(CENTER);
    image(rice_icon, 420, 20, 30, 30);
    image(food_icon, 460, 20, 30, 30);
    image(vegetable_icon, 500, 20, 30, 30);
    image(fruit_icon, 540, 20, 30, 30);
    image(salt_icon, 580, 20, 30, 30);
    image(egg_icon, 620, 20, 30, 30);

    if (tab_num== 0) {
      r = 240;
      g = 223;
      b = 0;
      fill(r, g, b);  //黄色
    }
    else if (tab_num== 1) {
      r = 245;
      g = 148;
      b = 109;
      fill(r, g, b);  //赤
    }
    else if (tab_num== 2) {
      r = 135;
      g = 239;
      b = 56;
      fill(r, g, b);  //緑
    }
    else if (tab_num== 3) {
      r = 250;
      g = 220;
      b = 170;
      fill(r, g, b); //クリーム
    }
    else if (tab_num== 4) {
      r = 12;
      g = 211;
      b = 231;
      fill(r, g, b);  //青
    }
    else if (tab_num== 5) {
      r = 249;
      g = 189;
      b = 71;
      fill(r, g, b);  //茶
    }
    rect(400, 40, 240, 440);  //タブアイコンの下の四角形

    imageMode(CENTER);
    // ページの矢印
    if (mouseY <= 90 && mouseY >= 40) {
      if (mouseX <= 460 && mouseX >= 400) {
        tint(255, 128);
        fill(r+20, g+20, b+20);
        rect(400, 40, 60, 50);
        image(page_left, 430, 65);
        noTint();
        image(page_right, 610, 65);
      }
      else if (mouseX <= 640 && mouseX >= 580) {
        tint(255, 128);
        fill(r+20, g+20, b+20);
        rect(580, 40, 60, 50);
        image(page_right, 610, 65);
        noTint();
        image(page_left, 430, 65);
      }
      else {
        image(page_left, 430, 65);
        image(page_right, 610, 65);
      }
    }
    else {
      image(page_left, 430, 65);
      image(page_right, 610, 65);
    }

    fill(80, 80, 80);
    textSize(35);
    text(page_num + "/" + max_page, 520, 77);
    strokeWeight(0.5);
    stroke(120, 120, 120);
    line(400, 90, 640, 90);
    image(tray, 200, 355, 400, 250);
    println("tab_array_size = " + tab_array_size);
    //右のメニュー表
    textSize(15);
    if (tab_array_size > 0 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][0 + 8*(page_num-1)]], 470, 155, 80, 80);
      text(jap_name[tab_array[tab_num][0 + 8*(page_num-1)]], 470, 120);
    }
    if (tab_array_size > 1 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][1 + 8*(page_num-1)]], 470, 255, 80, 80);
      text(jap_name[tab_array[tab_num][1 + 8*(page_num-1)]], 470, 220);
    }
    if (tab_array_size > 2 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][2 + 8*(page_num-1)]], 470, 355, 80, 80);
      text(jap_name[tab_array[tab_num][2 + 8*(page_num-1)]], 470, 320);
    }
    if (tab_array_size > 3 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][3 + 8*(page_num-1)]], 470, 455, 80, 80);
      text(jap_name[tab_array[tab_num][3 + 8*(page_num-1)]], 470, 420);
    }
    if (tab_array_size > 4 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][4 + 8*(page_num-1)]], 580, 155, 80, 80);
      text(jap_name[tab_array[tab_num][4 + 8*(page_num-1)]], 580, 120);
    }
    if (tab_array_size > 5 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][5 + 8*(page_num-1)]], 580, 255, 80, 80);
      text(jap_name[tab_array[tab_num][5 + 8*(page_num-1)]], 580, 220);
    }
    if (tab_array_size > 6 + 8 * (page_num-1)) {
      image(img[tab_array[tab_num][6 + 8*(page_num-1)]], 580, 355, 80, 80);
      text(jap_name[tab_array[tab_num][6 + 8*(page_num-1)]], 580, 320);
    }
    if (tab_array_size > 7 + 8*(page_num-1)) {
      image(img[tab_array[tab_num][7 + 8*(page_num-1)]], 580, 455, 80, 80);
      text(jap_name[tab_array[tab_num][7 + 8*(page_num-1)]], 580, 420);
    }

    if (mousePressed == true
    && dragged_id != 0) {
      tint(255,128);
      image(img[dragged_id], mouseX, mouseY, 80, 80);
      noTint();
    }
    //画像の表示
    for (int i=0; i < released_array_size; i++) {
      if (released_position[i][0] != 0
      && released_position[i][1] != 0) {
        image(img[released_id_array.get(i)], released_position[i][0], released_position[i][1], 80, 80);
      }
    }
    //ごみ箱の表示
    if ((mouseX <= 0 || mouseX >= 400 || mouseY <= 0 || mouseY >= 480)
    && trash_flag == true) {
      fill(234, 203, 235);
      noStroke();
      rect(0, 0, 400, 480);
      image(tray, 200, 355, 400, 250);
      for (int i=0; i < released_array_size; i++) {
        if (released_position[i][0] != 0
        && released_position[i][1] != 0) {
          image(img[released_id_array.get(i)], released_position[i][0], released_position[i][1], 80, 80);
        }
      }
      tint(255, 210);
      image(trash, 200, 240);
      noTint();
    }
    total_output_flag = true;
  }
  imageMode(CORNER);
  //mouseモードではないときの初期化
  if (mouse_flag == false) {
    released_id_array.clear();
    page_num = 1;
    tab_num = 0;
  }
}

void mousePressed() {
  pressed_flag = true;
  // メニュー以外の食品のクリック
  if (mouseX <= 400 && released_array_size > 0) {
    for (int pressed_idx = released_array_size-1; pressed_idx >= 0; pressed_idx--) {
      if (abs(released_position[pressed_idx][0] - mouseX) < 40
      && abs(released_position[pressed_idx][1] - mouseY) < 40) {
        dragged_id = released_id_array.get(pressed_idx);
        trash_flag = true;
        for (TableRow row : table.rows()) {
          int marker_id = row.getInt("marker_id");
          if (dragged_id == marker_id && mouseY > 235) {
            for (int i=0; i<MAXCOM; i++) {
              total[i] -= row.getFloat(composition[i]) * gram[dragged_id] / 100 * plus_array[dragged_id];
            }
            break;
          }
        }
        //配列の中身をクリックされた値から一つずつ前にずらす
        for (int i=pressed_idx; i < released_array_size; i++) {
          released_position[i][0] = released_position[i+1][0];
          released_position[i][1] = released_position[i+1][1];
        }
        released_id_array.remove(pressed_idx);
        released_array_size = released_id_array.size();
        break;
      }
      //クリックした範囲に食品がなかったとき
      else {
        dragged_id = 0;
      }
    }
  }
  //mouseモードのメニューの食品のクリック
  //左の列
  if (mouseX >= 470-40
  && mouseX <= 470+40) {
    if (mouseY >= 130-40
    && mouseY <= 130+40) {
      dragged_id = tab_array[tab_num][0 + 8*(page_num-1)];
    }
    else if (mouseY >= 230-40
    && mouseY <= 230+40) {
      dragged_id = tab_array[tab_num][1 + 8*(page_num-1)];
    }
    else if (mouseY >= 330-40
    && mouseY <= 330+40) {
      dragged_id = tab_array[tab_num][2 + 8*(page_num-1)];
    }
    else if (mouseY >= 430-40
    && mouseY <= 430+40) {
      dragged_id = tab_array[tab_num][3 + 8*(page_num-1)];
    }
    else {
      dragged_id = 0;
    }
  }
  //右の列
  else if (mouseX >= 580-40
  && mouseX <= 580+40) {
    if (mouseY >= 130-40
    && mouseY <= 130+40) {
      dragged_id = tab_array[tab_num][4 + 8*(page_num-1)];
    }
    else if (mouseY >= 230-40
    && mouseY <= 230+40) {
      dragged_id = tab_array[tab_num][5 + 8*(page_num-1)];
    }
    else if (mouseY >= 330-40
    && mouseY <= 330+40) {
      dragged_id = tab_array[tab_num][6 + 8*(page_num-1)];
    }
    else if (mouseY >= 430-40
    && mouseY <= 430+40) {
      dragged_id = tab_array[tab_num][7 + 8*(page_num-1)];
    }
    else {
      dragged_id = 0;
    }
  }
  else if (mouseX > 400) {
    dragged_id = 0;
  }
  //mouseモードのページ数の加減
  //mouseモードの左矢印
  if (mouseY <= 90 && mouseY >= 40) {
    if (mouseX <= 460
    && mouseX >= 400
    && page_num > 1) {
      page_num--;
    }
    //mouseモードの右矢印
    else if (mouseX <= 640
    && mouseX >= 580
    && page_num < max_page) {
      page_num++;
    }
  }
  //tabの切り替え
  if (mouseY > 0 && mouseY < 40) {
    if (mouseX > 400 && mouseX < 440) {
      tab_num = 0;
      tab_array_size = tab0_i;
    }
    else if (mouseX > 440 && mouseX < 480) {
      tab_num = 1;
      tab_array_size = tab1_i;
    }
    else if (mouseX > 480 && mouseX < 520) {
      tab_num = 2;
      tab_array_size = tab2_i;
    }
    else if (mouseX > 520 && mouseX < 560) {
      tab_num = 3;
      tab_array_size = tab3_i;
    }
    else if (mouseX > 560 && mouseX < 600) {
      tab_num = 4;
      tab_array_size = tab4_i;
    }
    else if (mouseX > 600 && mouseX < 640) {
      tab_num = 5;
      tab_array_size = tab5_i;
    }
    page_num = 1;  //切り替わるときにページ数を1に変更
    max_page = ceil(tab_array_size / 8);
  }
}

void mouseReleased() {
  if (pressed_flag == false) {
    return;
  }
  pressed_flag = false;
  if (mouseX <= 400
  && mouseX >= 0
  && mouseY <= 480
  && mouseY >= 0
  && dragged_id != 0) {
    released_x = mouseX;
    released_y = mouseY;
    for (TableRow row : table.rows()) {
      int marker_id = row.getInt("marker_id");
      if (dragged_id == marker_id) {
        released_id_array.add(dragged_id);
        released_array_size = released_id_array.size();
        released_position[released_array_size-1][0] = released_x;  //idではなくlistの中の順番でarrayに格納する
        released_position[released_array_size-1][1] = released_y;
        break;
      }
    }
    if (released_position[released_array_size-1][1] > 235) {  //トレイの上のとき
      for (TableRow row : table.rows()) {
        int marker_id = row.getInt("marker_id");
        if (dragged_id == marker_id) {
          for (int j=0; j<MAXCOM; j++) {
            total[j] += row.getFloat(composition[j]) * gram[dragged_id] / 100 * plus_array[dragged_id];
          }
          break;
        }
      }
    }
  }
  else {
    dragged_id = 0;
  }
  trash_flag = false;
}
