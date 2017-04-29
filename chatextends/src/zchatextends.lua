--******************************************
-- CHAT_EXTENDS
-- チャットフレームを拡張したアドオン
-- なるべく遅くに読み込んでほしいので、z始まりにしている
--******************************************

--アドオン名（大文字）
local addonName = "CHATEXTENDS";
local addonNameLower = string.lower(addonName);
--作者名
local author = "torahamu";

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {};
local g = _G["ADDONS"][author][addonName];

--設定ファイル保存先
g.settingsDirLoc = string.format("../addons/%s", addonNameLower);
g.settingsFileLoc = string.format("%s/settings.json", g.settingsDirLoc);
g.SAVE_DIR = "../release/screenshot";

--デフォルト設定
if not g.loaded then
  g.settings = {
	-- システムメッセージを全体フレームのみに表示するフラグ
	SYSTEM_TOTAL_FLG=true;
	-- 発言をニコニコ風に表示するフラグ
	NICO_CHAT_FLG=false;
	-- 発言を記録していくフラグ
	REC_CHAT_FLG=false;
	-- 吹き出し表示フラグ
	BALLON_FLG=false;
	-- タイプ表示フラグ
	ENABLE_TYPE_FLG=true;
  };
end

-- フォント設定
g.fontsettings = {
	COLOR_WHI_MY="FF7cd8ff";
	COLOR_WHI_TO="FFb4ddef";
	COLOR_NORMAL_MY="FFffe86a";
	COLOR_NORMAL="FFFFFFFF";
	COLOR_SHOUT_MY="FFff7c0f";
	COLOR_SHOUT="FFffa800";
	COLOR_PARTY_MY="FF93c95a";
	COLOR_PARTY="FFbceb89";
	COLOR_PARTY_INFO="FFbceb89";
	COLOR_GUILD_INFO="FFBE80CE";
	COLOR_GUILD_MY="FFa735dc";
	COLOR_GUILD="FFbe80ce";
	BALLONCHAT_FONTSTYLE="{#050505}";
	BALLONCHAT_FONTSTYLE_SYSTEM="{#DD0000}";
	BALLONCHAT_FONTSTYLE_MEMBER="{#000000}";
	TEXTCHAT_FONTSTYLE_NORMAL_MY="{#FFFAB8}{b}{ol}{ds}";
	TEXTCHAT_FONTSTYLE_SHOUT_MY="{#FFD03F}{b}{ol}{ds}";
	TEXTCHAT_FONTSTYLE_PARTY_MY="{#73FF97}{b}{ol}{ds}";
	TEXTCHAT_FONTSTYLE_GUILD_MY="{#DC99FF}{b}{ol}{ds}";
	TEXTCHAT_FONTSTYLE_WHISPER_MY="{#8EEBFF}{b}{ol}{ds}";
	TEXTCHAT_FONTSTYLE_NORMAL="{#FFFFFF}{ol}";
	TEXTCHAT_FONTSTYLE_SHOUT="{#da6e0f}{ol}";
	TEXTCHAT_FONTSTYLE_PARTY="{#86E57F}{ol}";
	TEXTCHAT_FONTSTYLE_GUILD="{#A566FF}{ol}";
	TEXTCHAT_FONTSTYLE_WHISPER="{#2ec2d4}{ol}";
	TEXTCHAT_FONTSTYLE_NOTICE="{#FF0000}{ol}";
	TEXTCHAT_FONTSTYLE_SYSTEM="{#FFE400}{ol}";
}

--ライブラリ読み込み
local acutil = require('acutil');

-- 読み込みフラグ
g.loaded=false

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonName));

-- フレーム内文字
if option.GetCurrentCountry()=="Japanese" then
	headertxt = "拡張設定";
	systemtxt = "システムメッセージを{nl}全体フレームのみに表示する";
	nicotxt = "チャット内容をニコニコ動画{nl}のように表示する";
	rectxt = "チャット内容を記録し続ける";
	ballontxt = "吹き出しで表示する";
	enable_type_txt = "簡易表示の時に{nl}発言の種類を表示する"
else
	headertxt = "extends setting";
	systemtxt = "Display system messages{nl}only in the total frame";
	nicotxt = "Chat contents{nl}flow from the right";
	rectxt = "Record Chat Content";
	ballontxt = "Ballon Chat";
	enable_type_txt = "Display the type of remark{nl}at the time of simple chat"
end

function CHATEXTENDS_SAVE_SETTINGS()
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

--マップ読み込み時処理（1度だけ）
function ZCHATEXTENDS_ON_INIT(addon, frame)
	-- 初期設定項目は1度だけ行う
	if g.loaded==false then
		g.addon = addon;
		g.frame = frame;

		-- 元関数封印
		if nil == CHATEXTENDS_DRAW_CHAT_MSG_OLD then
			CHATEXTENDS_DRAW_CHAT_MSG_OLD = DRAW_CHAT_MSG;
			DRAW_CHAT_MSG = CHATEXTENDS_DRAW_CHAT_MSG;
		end
		if nil == CHATEXTENDS_CHAT_CHAT_SET_TO_TITLENAME_OLD then
			CHATEXTENDS_CHAT_CHAT_SET_TO_TITLENAME_OLD = CHAT_SET_TO_TITLENAME;
			CHAT_SET_TO_TITLENAME = CHATEXTENDS_CHAT_CHAT_SET_TO_TITLENAME;
		end
		if nil == CHATEXTENDS_CHAT_OPEN_INIT_OLD then
			CHATEXTENDS_CHAT_OPEN_INIT_OLD = CHAT_OPEN_INIT;
			CHAT_OPEN_INIT = CHATEXTENDS_CHAT_OPEN_INIT;
		end

		if nil == CHATEXTENDS_CHAT_SET_FONTSIZE_N_COLOR_OLD then
			CHATEXTENDS_CHAT_SET_FONTSIZE_N_COLOR_OLD = CHAT_SET_FONTSIZE_N_COLOR;
			CHAT_SET_FONTSIZE_N_COLOR = CHATEXTENDS_CHAT_SET_FONTSIZE_N_COLOR;
		end

		if nil == CHATEXTENDS_SetChatType_OLD then
			CHATEXTENDS_SetChatType_OLD = _G['ui'].SetChatType;
			_G['ui'].SetChatType = CHATEXTENDS_SetChatType;
		end

		if nil == CHATEXTENDS_ProcessTabKey_OLD then
			CHATEXTENDS_ProcessTabKey_OLD = _G['ui'].ProcessTabKey;
			_G['ui'].ProcessTabKey = CHATEXTENDS_ProcessTabKey;
		end

		--コマンド登録
		acutil.slashCommand("/savechat", CHATEXTENDS_SAVE_CHAT);

		-- 設定読み込み
		if not g.loaded then
			local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
			-- 読み込めない = ファイルがない
			if err then
				-- ファイル作る
				CHATEXTENDS_SAVE_SETTINGS();
			else
				-- 読み込めたら読み込んだ値使う
				g.settings = t;
				CHATEXTENDS_SAVE_SETTINGS();
			end
			-- savechatフォルダあればそっちをデフォルトに
			if CHATEXTENDS_CHECK_DIR("../release/savechat") then
				g.SAVE_DIR = "../release/savechat";
			else
				g.SAVE_DIR = "../release/screenshot";
			end
			g.loaded = true;
		end
	end

	-- 設定項目をチャットオプションに追加
	CHATEXTENDS_CREATE_CHATOPTION_FRAME();
end

-- チャット入力を変更
function CHATEXTENDS_UPDATE_CHAT_FRAME()
	local chat_frame = ui.GetFrame("chat");
	chat_frame:Resize(750,chat_frame:GetHeight());
	chat_frame:SetOffset(chat_frame:GetX(),805);
	chat_frame:EnableMove(0);
	local edit_bg=GET_CHILD(chat_frame,"edit_bg");
	edit_bg:Resize(742,36);
	local mainchat=GET_CHILD(chat_frame,"mainchat");
	local titleCtrl = GET_CHILD(chat_frame,'edit_to_bg');
	titleCtrl:SetGravity(ui.LEFT, ui.TOP);
	local offsetX = 100;
	mainchat:SetGravity(ui.LEFT, ui.TOP);
	mainchat:Resize(600 - titleCtrl:GetWidth() - offsetX + 10, mainchat:GetOriginalHeight())
	mainchat:SetOffset(titleCtrl:GetWidth() + offsetX, mainchat:GetOriginalY());

	local now_button = chat_frame:CreateOrGetControl("button", "CHATEXTENDS_NOW_BUTTON", 72, 0, 36, 36);
	tolua.cast(now_button, "ui::CButton");
	now_button:SetGravity(ui.RIGHT, ui.TOP);
	now_button:SetOffset(72, -1);
	now_button:SetClickSound("button_click");
	now_button:SetOverSound("button_cursor_over_2");
	now_button:SetAnimation("MouseOnAnim", "btn_mouseover");
	now_button:SetAnimation("MouseOffAnim", "btn_mouseoff");
	now_button:SetEventScript(ui.LBUTTONDOWN, "CHATEXTENDS_MY_POS");
	now_button:SetImage("button_pos_img");
	now_button:Resize(37, 37);

	local party_button = chat_frame:CreateOrGetControl("button", "CHATEXTENDS_PARTY_BUTTON", 107, 0, 36, 36);
	tolua.cast(party_button, "ui::CButton");
	party_button:SetGravity(ui.RIGHT, ui.TOP);
	party_button:SetOffset(107, -1);
	party_button:SetClickSound("button_click");
	party_button:SetOverSound("button_cursor_over_2");
	party_button:SetAnimation("MouseOnAnim", "btn_mouseover");
	party_button:SetAnimation("MouseOffAnim", "btn_mouseoff");
	party_button:SetEventScript(ui.LBUTTONDOWN, "LINK_PARTY_INVITE");
	party_button:SetImage("link_party");
	party_button:SetImage("button_party");
	party_button:Resize(37, 37);

	local button_emo=GET_CHILD(chat_frame,"button_emo");
	button_emo:SetOffset(39,0);

	local button_option = chat_frame:CreateOrGetControl("button", "CHATEXTENDS_BUTTON_OPTION", 6, 0, 36, 36);
	tolua.cast(button_option, "ui::CButton");
	button_option:SetGravity(ui.RIGHT, ui.TOP);
	button_option:SetOffset(6, 0);
	button_option:SetClickSound("button_click");
	button_option:SetOverSound("button_cursor_over_2");
	button_option:SetAnimation("MouseOnAnim", "btn_mouseover");
	button_option:SetAnimation("MouseOffAnim", "btn_mouseoff");
	button_option:SetEventScript(ui.LBUTTONDOWN, "CHAT_OPEN_OPTION");
	button_option:SetImage("button_chat_option");
	button_option:Resize(36, 36);
end

-- 現在値を挿入
function CHATEXTENDS_MY_POS()
	-- mapフレームの子供のmapがマップ画像　ややこしいわ
	local map_frame = ui.GetFrame("map");
	local map_pic = GET_CHILD(map_frame,"map");
	-- 自分の座標
	local myposition = GET_CHILD(map_frame,"my");
	local x, y= GET_C_XY(myposition);
	x = x + (myposition:GetWidth()/2) - map_pic:GetX();
	y = y + (myposition:GetHeight()/2) - map_pic:GetY();
	local mapName = session.GetMapName();
	local mapprop = geMapTable.GetMapProp(mapName);
	local worldPos = mapprop:MinimapPosToWorldPos(x, y, map_pic:GetWidth(), map_pic:GetHeight());
	LINK_MAP_POS(mapName, worldPos.x ,worldPos.y);
end

-- チャットオプションフレームに設定追加
function CHATEXTENDS_CREATE_CHATOPTION_FRAME()
	local chat_option_frame = ui.GetFrame("chat_option");
	chat_option_frame:Resize(600,chat_option_frame:GetHeight());
	local tabgbox1 = GET_CHILD(chat_option_frame ,"tabgbox1");
	tabgbox1:SetGravity(ui.LEFT, ui.TOP);
	tabgbox1:SetOffset(37, tabgbox1:GetY());
	local tabgbox2 = GET_CHILD(chat_option_frame ,"tabgbox2");
	tabgbox2:SetGravity(ui.LEFT, ui.TOP);
	tabgbox2:SetOffset(37, tabgbox2:GetY());
	local tabgbox3 = GET_CHILD(chat_option_frame ,"tabgbox3");
	tabgbox3:SetGravity(ui.LEFT, ui.TOP);
	tabgbox3:SetOffset(37, tabgbox3:GetY());

	local header = chat_option_frame:CreateOrGetControl("richtext", "CHATEXTENDS_HEADER", 300, 43, 120, 34);
	tolua.cast(header, 'ui::CRichText');
	header:SetFontName("white_16_ol");
	header:SetText("{@st42}"..headertxt.."{/}");

	local system_total_flg_chk = chat_option_frame:CreateOrGetControl('checkbox', "CHATEXTENDS_SYSTEM_TOTAL_FLG", 315, 65, 120, 24);
	system_total_flg_chk = tolua.cast(system_total_flg_chk, "ui::CCheckBox");
	system_total_flg_chk:SetFontName("white_16_ol");
	system_total_flg_chk:SetText(systemtxt);
	system_total_flg_chk:SetClickSound('button_click_big');
	system_total_flg_chk:SetAnimation("MouseOnAnim", "btn_mouseover");
	system_total_flg_chk:SetAnimation("MouseOffAnim", "btn_mouseoff");
	system_total_flg_chk:SetOverSound('button_over');
	system_total_flg_chk:SetEventScript(ui.LBUTTONUP, "CHATEXTENDS_TOGGLE_SYSTEM_TOTAL_FLG");
	if g.settings.SYSTEM_TOTAL_FLG then
		system_total_flg_chk:SetCheck(1);
	else
		system_total_flg_chk:SetCheck(0);
	end

	local nico_chat_flg_chk = chat_option_frame:CreateOrGetControl('checkbox', "CHATEXTENDS_NICO_CHAT_FLG", 315, 115, 120, 24);
	nico_chat_flg_chk = tolua.cast(nico_chat_flg_chk, "ui::CCheckBox");
	nico_chat_flg_chk:SetFontName("white_16_ol");
	nico_chat_flg_chk:SetText(nicotxt);
	nico_chat_flg_chk:SetClickSound('button_click_big');
	nico_chat_flg_chk:SetAnimation("MouseOnAnim", "btn_mouseover");
	nico_chat_flg_chk:SetAnimation("MouseOffAnim", "btn_mouseoff");
	nico_chat_flg_chk:SetOverSound('button_over');
	nico_chat_flg_chk:SetEventScript(ui.LBUTTONUP, "CHATEXTENDS_TOGGLE_NICO_CHAT_FLG");
	if g.settings.NICO_CHAT_FLG then
		nico_chat_flg_chk:SetCheck(1);
	else
		nico_chat_flg_chk:SetCheck(0);
	end

	local rec_chat_flg_chk = chat_option_frame:CreateOrGetControl('checkbox', "CHATEXTENDS_REC_CHAT_FLG", 315, 165, 120, 24);
	rec_chat_flg_chk = tolua.cast(rec_chat_flg_chk, "ui::CCheckBox");
	rec_chat_flg_chk:SetFontName("white_16_ol");
	rec_chat_flg_chk:SetText(rectxt);
	rec_chat_flg_chk:SetClickSound('button_click_big');
	rec_chat_flg_chk:SetAnimation("MouseOnAnim", "btn_mouseover");
	rec_chat_flg_chk:SetAnimation("MouseOffAnim", "btn_mouseoff");
	rec_chat_flg_chk:SetOverSound('button_over');
	rec_chat_flg_chk:SetEventScript(ui.LBUTTONUP, "CHATEXTENDS_TOGGLE_REC_CHAT_FLG");
	if g.settings.REC_CHAT_FLG then
		rec_chat_flg_chk:SetCheck(1);
	else
		rec_chat_flg_chk:SetCheck(0);
	end

	local ballon_flg_chk = chat_option_frame:CreateOrGetControl('checkbox', "CHATEXTENDS_BALLON_FLG", 315, 215, 120, 24);
	ballon_flg_chk = tolua.cast(ballon_flg_chk, "ui::CCheckBox");
	ballon_flg_chk:SetFontName("white_16_ol");
	ballon_flg_chk:SetText(ballontxt);
	ballon_flg_chk:SetClickSound('button_click_big');
	ballon_flg_chk:SetAnimation("MouseOnAnim", "btn_mouseover");
	ballon_flg_chk:SetAnimation("MouseOffAnim", "btn_mouseoff");
	ballon_flg_chk:SetOverSound('button_over');
	ballon_flg_chk:SetEventScript(ui.LBUTTONUP, "CHATEXTENDS_TOGGLE_BALLON_FLG");
	if g.settings.BALLON_FLG then
		ballon_flg_chk:SetCheck(1);
	else
		ballon_flg_chk:SetCheck(0);
	end

	local enable_type_flg_chk = chat_option_frame:CreateOrGetControl('checkbox', "CHATEXTENDS_ENABLE_TYPE_FLG", 315, 265, 120, 24);
	enable_type_flg_chk = tolua.cast(enable_type_flg_chk, "ui::CCheckBox");
	enable_type_flg_chk:SetFontName("white_16_ol");
	enable_type_flg_chk:SetText(enable_type_txt);
	enable_type_flg_chk:SetClickSound('button_click_big');
	enable_type_flg_chk:SetAnimation("MouseOnAnim", "btn_mouseover");
	enable_type_flg_chk:SetAnimation("MouseOffAnim", "btn_mouseoff");
	enable_type_flg_chk:SetOverSound('button_over');
	enable_type_flg_chk:SetEventScript(ui.LBUTTONUP, "CHATEXTENDS_TOGGLE_ENABLE_TYPE_FLG");
	if g.settings.ENABLE_TYPE_FLG then
		enable_type_flg_chk:SetCheck(1);
	else
		enable_type_flg_chk:SetCheck(0);
	end

end

-- チャットオープン処理
function CHATEXTENDS_CHAT_OPEN_INIT()
	-- 元関数呼び出し
	CHATEXTENDS_CHAT_OPEN_INIT_OLD();
	-- チャット入力を変更
	CHATEXTENDS_UPDATE_CHAT_FRAME();
end

-- チェックボックスのイベント
function CHATEXTENDS_TOGGLE_SYSTEM_TOTAL_FLG(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.settings.SYSTEM_TOTAL_FLG = true;
	else
		g.settings.SYSTEM_TOTAL_FLG = false;
	end
	CHATEXTENDS_SAVE_SETTINGS();
end

-- チェックボックスのイベント
function CHATEXTENDS_TOGGLE_NICO_CHAT_FLG(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.settings.NICO_CHAT_FLG = true;
	else
		g.settings.NICO_CHAT_FLG = false;
	end
	CHATEXTENDS_SAVE_SETTINGS();
end

-- チェックボックスのイベント
function CHATEXTENDS_TOGGLE_REC_CHAT_FLG(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.settings.REC_CHAT_FLG = true;
	else
		g.settings.REC_CHAT_FLG = false;
	end
	CHATEXTENDS_SAVE_SETTINGS();
end

-- チェックボックスのイベント
function CHATEXTENDS_TOGGLE_BALLON_FLG(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.settings.BALLON_FLG = true;
	else
		g.settings.BALLON_FLG = false;
	end
	CHATEXTENDS_SAVE_SETTINGS();
	ui.ReDrawAllChatMsg();
end
-- チェックボックスのイベント
function CHATEXTENDS_TOGGLE_ENABLE_TYPE_FLG(frame, ctrl, argStr, argNum)
	if ctrl:IsChecked() == 1 then
		g.settings.ENABLE_TYPE_FLG = true;
	else
		g.settings.ENABLE_TYPE_FLG = false;
	end
	CHATEXTENDS_SAVE_SETTINGS();
	if g.settings.BALLON_FLG == false then
		ui.ReDrawAllChatMsg();
	end
end



-- チャットサイズの設定
-- タイプを変えたりささやき相手の名前表示したりしたら、入力フレームがリサイズされるので、その対策
function CHATEXTENDS_CHAT_CHAT_SET_TO_TITLENAME(chatType, targetName, count)
	CHATEXTENDS_CHAT_CHAT_SET_TO_TITLENAME_OLD(chatType, targetName, count)
	local chat_frame = ui.GetFrame('chat');
	local mainchat = GET_CHILD(chat_frame, 'mainchat');
	local titleCtrl = GET_CHILD(chat_frame,'edit_to_bg');
	local offsetX = 100;

	mainchat:Resize(600 - titleCtrl:GetWidth() - offsetX + 10, mainchat:GetOriginalHeight())
	mainchat:SetOffset(titleCtrl:GetWidth() + offsetX, mainchat:GetOriginalY());

end

-- チャットタイプ選択フック
function CHATEXTENDS_SetChatType(typeIvalue)
	-- 一度チャット内容を取得
	local str = GET_CHAT_TEXT();
	-- この命令でチャット内容が消える
	CHATEXTENDS_SetChatType_OLD(typeIvalue);
	-- チャット内容復旧
	SET_CHAT_TEXT(str);
end

-- タブキー押下時のフック
function CHATEXTENDS_ProcessTabKey()
	local frame = ui.GetFrame('chat');
	local chatEditCtrl = frame:GetChild('mainchat');
	if chatEditCtrl:IsHaveFocus() == 1 then
		-- 一度チャット内容を取得
		local str = GET_CHAT_TEXT();
		-- この命令でチャット内容が消える
		CHATEXTENDS_ProcessTabKey_OLD();
		-- チャット内容復旧
		SET_CHAT_TEXT(str);
	else
		CHATEXTENDS_ProcessTabKey_OLD();
	end
end

--************************************************
-- DRAW_CHAT_MSGのフック
-- 　引数：String groupboxname
-- 　　　　処理対象のgbox名
-- 　　　　gboxはframe:chatframe内のframeオブジェクト
-- 　引数：int startindex
-- 　　　　チャット配列の表示処理開始index
-- 　引数：String framename
-- 　　　　処理対象フレーム名
--************************************************
function CHATEXTENDS_DRAW_CHAT_MSG(groupboxname, startindex, chatframe)
	local mainchatFrame = ui.GetFrame("chatframe")
	local groupbox = GET_CHILD(chatframe, groupboxname);
	local size = session.ui.GetMsgInfoSize(groupboxname)
	local nicoflg = true;
	local recflg = true;

	if groupbox == nil then
		return 1;
	end

	if groupbox:IsVisible() == 0 then
		return 1;
	end
	if chatframe:IsVisible() == 0 then
		return 1;
	end

	if startindex == 0 then
		DESTROY_CHILD_BYNAME(groupbox, "cluster_");
		nicoflg = false;
		recflg = false;
	end


	local marginLeft = 20;
	local marginRight = 0;
	local ypos = 0;

	for i = startindex , size - 1 do
		if i ~= 0 then
			local clusterinfo = session.ui.GetChatMsgInfo(groupboxname, i-1)
			if clusterinfo ~= nil then
				local beforechildname = "cluster_"..clusterinfo:GetMsgInfoID()
				local beforechild = GET_CHILD(groupbox, beforechildname);
				if beforechild ~= nil then
					ypos = beforechild:GetY() + beforechild:GetHeight();
				end
			end
		end

		local clusterinfo = session.ui.GetChatMsgInfo(groupboxname, i)
		if clusterinfo == nil then
			return 0;
		end
		local clustername = "cluster_"..clusterinfo:GetMsgInfoID();
		local msgType = clusterinfo:GetMsgType();
		local commnderName = clusterinfo:GetCommanderName();

		local colorType = session.chat.GetRoomConfigColorType(clusterinfo:GetRoomID())
		local colorCls = GetClassByType("ChatColorStyle", colorType)

		local fontSize = GET_CHAT_FONT_SIZE();

		local offsetX = chatframe:GetUserConfig("CTRLSET_OFFSETX");
		if g.settings.BALLON_FLG then
			CHATEXTENDS_BALLON_DRAW(groupboxname, groupbox, clustername, clusterinfo, commnderName, msgType, marginRight, marginLeft, ypos, fontSize)
		else

			local chatCtrl = groupbox:CreateOrGetControlSet('chatTextVer', clustername, ui.LEFT, ui.TOP, marginLeft, ypos , marginRight, 1);

			-- システムメッセージ削除処理
			if ( g.settings.SYSTEM_TOTAL_FLG and (msgType == "System" or msgType == "Notice") and groupboxname ~= "chatgbox_TOTAL") then
				chatCtrl:SetOffset( 0 , ypos);
				chatCtrl:Resize( 0 , 0);
				chatCtrl:ShowWindow(0);
			else

				chatCtrl:EnableHitTest(1);
				chatCtrl:EnableAutoResize(true,false);


				if commnderName ~= GETMYFAMILYNAME() then
					chatCtrl:SetSkinName("")
				end
				local commnderNameUIText = commnderName .. " : "

				local label = chatCtrl:GetChild('bg');
				local txt = GET_CHILD(chatCtrl, "text");
				local timeCtrl = GET_CHILD(chatCtrl, "time");

				local msgFront = "";
				local msgString = "";
				local fontStyle = nil;
				local msgIsMine = false;

				if commnderName == GETMYFAMILYNAME() then
					msgIsMine = true;
					label:SetColorTone("FF000000");
					label:SetAlpha(60);
				else
					label:SetAlpha(0);
				end;

				if msgType == "friendmem" then

					fontStyle = mainchatFrame:GetUserConfig("TEXTCHAT_FONTSTYLE_SYSTEM");
					msgFront = "#86E57F";

				elseif msgType == "guildmem" then

					fontStyle = mainchatFrame:GetUserConfig("TEXTCHAT_FONTSTYLE_SYSTEM");
					msgFront = "#A566FF";

				elseif msgType ~= "System" then


					chatCtrl:SetEventScript(ui.RBUTTONDOWN, 'CHAT_RBTN_POPUP');
					chatCtrl:SetUserValue("TARGET_NAME", commnderName);

					txt:SetEventScript(ui.RBUTTONDOWN, 'CHAT_RBTN_POPUP');
					txt:SetUserValue("TARGET_NAME", commnderName);

					if msgType == "Normal" then

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_NORMAL");
						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_1"), commnderNameUIText);

					elseif msgType == "Shout" then

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_SHOUT");
						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_2"), commnderNameUIText);

					elseif msgType == "Party" then

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_PARTY");
						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_3"), commnderNameUIText);

					elseif msgType == "Guild" then

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_GUILD");
						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_4"), commnderNameUIText);

					elseif msgType == "Notice" then

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_NOTICE");
						msgFront = string.format("[%s]", ScpArgMsg("ChatType_8"));

					elseif msgType == "Whisper" then

						chatCtrl:SetEventScript(ui.LBUTTONDOWN, 'CHAT_GBOX_LBTN_DOWN');
						chatCtrl:SetEventScriptArgString(ui.LBUTTONDOWN, clusterinfo:GetRoomID());

						txt:SetUserValue("ROOM_ID", clusterinfo:GetRoomID());

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_WHISPER");

						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_5"), commnderNameUIText);

					elseif msgType == "Group" then

						chatCtrl:SetEventScript(ui.LBUTTONDOWN, 'CHAT_GBOX_LBTN_DOWN');
						chatCtrl:SetEventScriptArgString(ui.LBUTTONDOWN, clusterinfo:GetRoomID());

						txt:SetUserValue("ROOM_ID", clusterinfo:GetRoomID());

						fontStyle = CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, "TEXTCHAT_FONTSTYLE_WHISPER");

						msgFront = CHATEXTENDS_GET_TYPE_CHARNAME(ScpArgMsg("ChatType_6"), commnderNameUIText);
					else
						chatCtrl:SetEventScript(ui.LBUTTONDOWN, 'CHAT_GBOX_LBTN_DOWN');
						chatCtrl:SetEventScriptArgString(ui.LBUTTONDOWN, clusterinfo:GetRoomID());

						txt:SetUserValue("ROOM_ID", clusterinfo:GetRoomID());

						if colorCls ~= nil then
							fontStyle = "{#"..colorCls.TextColor.."}{ol}"
						end

						msgFront = commnderNameUIText;
					end

				elseif msgType == "System" then

					fontStyle = mainchatFrame:GetUserConfig("TEXTCHAT_FONTSTYLE_SYSTEM");
					msgFront = string.format("[%s]", ScpArgMsg("ChatType_7"));
				end

				local tempMsg = clusterinfo:GetMsg()
				if msgType == "friendmem" or  msgType == "guildmem" then
					msgString = string.format("{%s}%s{nl}",msgFront, tempMsg);
				else
					msgString = string.format("%s%s{nl}", msgFront, tempMsg);
				end

				local tempfontSize = string.format("{s%s}", fontSize);
				local msgString = clusterinfo:GetMsg();

				msgString = string.format("%s%s{/}{/}", tempfontSize, msgString);
				txt:SetTextByKey("font", fontStyle);
				txt:SetTextByKey("size", fontSize);
				txt:SetTextByKey("text", CHAT_TEXT_LINKCHAR_FONTSET(mainchatFrame, msgString));

				timeCtrl:SetTextByKey("time", clusterinfo:GetTimeStr());

				local slflag = string.find(clusterinfo:GetMsg(),'a SL%a')
				if slflag == nil then
					txt:EnableHitTest(0)
				else
					txt:EnableHitTest(1)
				end

				RESIZE_CHAT_CTRL(groupbox, chatCtrl, label, txt, timeCtrl, offsetX);
			end
		end
		-- ニコニコ表示
		CHATEXTENDS_NICO_CHAT_DRAW(nicoflg, groupboxname, clusterinfo, msgType, chatframe);
		-- チャット保存
		CHATEXTENDS_CHAT_REC(recflg, groupboxname, clusterinfo, msgType, chatframe)
	end


	local scrollend = false
	if groupbox:GetLineCount() == groupbox:GetCurLine() + groupbox:GetVisibleLineCount() then
		scrollend = true;
	end

	local beforeLineCount = groupbox:GetLineCount();
	groupbox:UpdateData();

	local afterLineCount = groupbox:GetLineCount();
	local changedLineCount = afterLineCount - beforeLineCount;
	local curLine = groupbox:GetCurLine();

	if (config.GetXMLConfig("ToggleBottomChat") == 1) or (scrollend == true) then
		groupbox:SetScrollPos(99999);
	else 
		groupbox:SetScrollPos(curLine + changedLineCount);
	end

	local gboxtype = string.sub(groupboxname,string.len("chatgbox_") + 1)
	local tonumberret = tonumber(gboxtype)

    if tonumberret ~= nil and tonumberret > (2^CHAT_TAB_TYPE_COUNT) - 1 then
		UPDATE_READ_FLAG_BY_GBOX_NAME("chatgbox_" .. gboxtype)
	end

	return 1
end

-- ***************************************
-- 簡易表示のメッセージ色
-- ***************************************
function CHATEXTENDS_CHAT_TEXT_IS_MINE_AND_SETFONT(msgIsMine, fontName)
	local result = fontName;
	if true == msgIsMine then
		result = fontName .. "_MY";
	end
	return g.fontsettings[result];
end


-- ***************************************
-- 簡易表示のタイプ：キャラ名の部分の取得
-- ***************************************
function CHATEXTENDS_GET_TYPE_CHARNAME(type, charname)
	if g.settings.ENABLE_TYPE_FLG then
		return string.format("[%s]%s", type, charname);
	else
		return string.format("%s", charname);
	end
end

-- ***************************************
-- ニコニコ表示用
-- ***************************************
function CHATEXTENDS_NICO_CHAT_DRAW(nicoflg, groupboxname, clusterinfo, msgType, chatframe)
	-- 設定のニコフラグがON
	if (g.settings.NICO_CHAT_FLG) then
	-- 発言はニコニコ風に出していい、かつメインフレーム、かつシステムメッセージではない、かつ全体フレーム
		if (nicoflg) and (chatframe == ui.GetFrame("chatframe")) and (msgType ~= "Notice") and (msgType ~= "System") and (groupboxname == "chatgbox_TOTAL") then
			-- 内容
			local nicoMsg = string.gsub(clusterinfo:GetMsg(), "({/}{/})", "%1{@st64}");
			NICO_CHAT(string.format("[%s] : %s", clusterinfo:GetCommanderName(), nicoMsg));
		end
	end
end

-- ***************************************
-- 発言レコード保存
-- ***************************************
function CHATEXTENDS_CHAT_REC(recflg, groupboxname, clusterinfo, msgType, chatframe)
	-- 設定の録画フラグがON
	if (g.settings.REC_CHAT_FLG) then
		-- 発言は録画していい、かつメインフレーム、かつシステムメッセージではない、かつ全体フレーム
		if (recflg) and (chatframe == ui.GetFrame("chatframe")) and (msgType ~= "Notice") and (msgType ~= "System") and (groupboxname == "chatgbox_TOTAL") then
			-- ファイル名に使用する時間
			local time = geTime.GetServerSystemTime();
			local year = string.format("%04d",time.wYear);
			local month = string.format("%02d",time.wMonth);
			local day = string.format("%02d",time.wDay);

			-- ファイル名は recchat_YYYYMMDD_キャラ名.txt
			local logfile=string.format("recchat_%s%s%s_%s.txt", year,month,day,GETMYPCNAME());

			-- ファイル追記モード
			file,err = io.open(g.SAVE_DIR.."/"..logfile, "a");
			file:write(CHATEXTENDS_GET_MSGBODY(clusterinfo,clusterinfo:GetMsg()));
			file:close();
		end
	end
end

-- ***************************************
-- 吹き出し表示
-- ***************************************
function CHATEXTENDS_BALLON_DRAW(groupboxname, groupbox, clustername, clusterinfo, commnderName, msgType, marginRight, marginLeft, ypos, fontSize)
	local cluster = GET_CHILD(groupbox, clustername);
	local tempfontSize = string.format("{s%s}", fontSize);

	if cluster ~= nil then

		-- システムメッセージ削除処理
		if ( g.settings.SYSTEM_TOTAL_FLG and (msgType == "System" or msgType == "Notice") and groupboxname ~= "chatgbox_TOTAL") then
			cluster:SetOffset( 0 , ypos);
			cluster:Resize( 0 , 0);
			cluster:ShowWindow(0);
		else
			local fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE;
			local label = cluster:GetChild('bg');

			if msgType == "System" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_SYSTEM;
			elseif msgType == "friendmem" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_MEMBER;
			elseif msgType == "guildmem" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_MEMBER;
			end
			local txt = GET_CHILD(label, "text");
			local msgString = clusterinfo:GetMsg();
			msgString = string.format("%s%s{/}{/}", tempfontSize, msgString);
			txt:SetTextByKey("font", fontStyle);
			txt:SetTextByKey("size", fontSize);
			txt:SetTextByKey("text", msgString);

			local timeBox = GET_CHILD(cluster, "timebox");
			CHATEXTENDS_RESIZE_CHAT_CTRL_BALLON(cluster, label, txt, timeBox)

			if cluster:GetHorzGravity() == ui.RIGHT then
				cluster:SetOffset( marginRight , ypos + 5); 
			else
				cluster:SetOffset( marginLeft , ypos + 5); 
			end

			local slflag = string.find(clusterinfo:GetMsg(),'a SL%a')
			if slflag == nil then
				label:EnableHitTest(0)
			else
				label:EnableHitTest(1)
			end
		end

	else

		local chatCtrlName = 'chatu';
		if commnderName == GETMYFAMILYNAME() then
			chatCtrlName = 'chati';
		end
		local horzGravity = ui.LEFT;
		if chatCtrlName == 'chati' then
			horzGravity = ui.RIGHT;
		end
		local chatCtrl = groupbox:CreateOrGetControlSet(chatCtrlName, clustername, horzGravity, ui.TOP, marginLeft, ypos + 5, marginRight, 0);
		-- システムメッセージ削除処理
		if ( g.settings.SYSTEM_TOTAL_FLG and (msgType == "System" or msgType == "Notice") and groupboxname ~= "chatgbox_TOTAL") then
			chatCtrl:SetOffset( 0 , ypos);
			chatCtrl:Resize( 0 , 0);
			chatCtrl:ShowWindow(0);
		else
			chatCtrl:EnableHitTest(1);

			local label = chatCtrl:GetChild('bg');
			local fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE;
			if msgType == "friendmem" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_MEMBER;
			elseif msgType == "guildmem" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_MEMBER;
			elseif msgType ~= "System" then
				chatCtrl:SetEventScript(ui.RBUTTONDOWN, 'CHAT_RBTN_POPUP');
				chatCtrl:SetUserValue("TARGET_NAME", commnderName);
			elseif msgType == "System" then
				fontStyle = g.fontsettings.BALLONCHAT_FONTSTYLE_SYSTEM;
			end

			local myColor, targetColor = CHATEXTENDS_GET_CHAT_COLOR(msgType);
			local txt = GET_CHILD(label, "text", "ui::CRichText");
			local timeBox = GET_CHILD(chatCtrl, "timebox", "ui::CGroupBox");
			local timeCtrl = GET_CHILD(timeBox, "time", "ui::CRichText");
			local nameText = GET_CHILD(chatCtrl, "name", "ui::CRichText");

			local msgString = clusterinfo:GetMsg();
			msgString = string.format("%s%s{/}{/}", tempfontSize, msgString);
			txt:SetTextByKey("font", fontStyle);
			txt:SetTextByKey("size", fontSize);
			txt:SetTextByKey("text", msgString);

			local labelMarginX = 0
			local labelMarginY = 0

			if chatCtrlName == 'chati' then
				label:SetSkinName('textballoon_i');
				label:SetColorTone(myColor);
			else
				label:SetColorTone(targetColor);
				if commnderName == "guildmem" or commnderName == "friendmem" then
					chatCtrl:RemoveChild("name");
				elseif commnderName == 'System' then
					nameText:SetText('{img chat_system_icon 65 18 }{/}');
				else
					nameText:SetText('{@st61}'..commnderName..'{/}');
					nameText:SetEventScript(ui.RBUTTONDOWN, 'CHAT_RBTN_POPUP');
					nameText:SetUserValue("TARGET_NAME", commnderName);
				end

				local iconPicture = GET_CHILD(chatCtrl, "iconPicture", "ui::CPicture");
				iconPicture:ShowWindow(0);
			end

			timeCtrl:SetTextByKey("time", clusterinfo:GetTimeStr());

			local slflag = string.find(clusterinfo:GetMsg(),'a SL%a')
			if slflag == nil then
				label:EnableHitTest(0)
			else
				label:EnableHitTest(1)
			end
			UPDATE_READ_FLAG_BY_GBOX_NAME(groupboxname);
			CHATEXTENDS_RESIZE_CHAT_CTRL_BALLON(chatCtrl, label, txt, timeBox);
		end
	end
end

function CHATEXTENDS_GET_CHAT_COLOR(msgType)

	local myColor = g.fontsettings.COLOR_WHI_MY;
	local targetColor = g.fontsettings.COLOR_WHI_TO;
	
	if msgType == 'Normal' then
		myColor = g.fontsettings.COLOR_NORMAL_MY;
		targetColor = g.fontsettings.COLOR_NORMAL;
	elseif msgType == 'Shout' then
		myColor = g.fontsettings.COLOR_SHOUT_MY;
		targetColor = g.fontsettings.COLOR_SHOUT;
	elseif msgType == 'Party' then
		myColor = g.fontsettings.COLOR_PARTY_MY;
		targetColor = g.fontsettings.COLOR_PARTY;	
	elseif msgType == 'Guild' then
		myColor = g.fontsettings.COLOR_GUILD_MY;
		targetColor = g.fontsettings.COLOR_GUILD;	
	elseif msgType == "friendmem" then
		targetColor = g.fontsettings.COLOR_PARTY_INFO;
	elseif msgType == "guildmem" then
		targetColor = g.fontsettings.COLOR_GUILD_INFO;
	elseif msgType == "System" then
		myColor = g.fontsettings.COLOR_NORMAL_MY;
		targetColor = g.fontsettings.COLOR_NORMAL;
	end

	return myColor, targetColor;

end

--************************************************
-- 吹き出しの表示位置調整
--************************************************
function CHATEXTENDS_RESIZE_CHAT_CTRL_BALLON(chatCtrl, label, txt, timeBox)

	local lablWidth = txt:GetWidth() + 40;
	local chatWidth = chatCtrl:GetWidth();
	label:Resize(lablWidth, txt:GetHeight() + 20);

	chatCtrl:Resize(chatWidth, label:GetY() + label:GetHeight() + 10);

	if chatCtrlName == 'chati' then
		local offsetX = label:GetX() + txt:GetWidth() - 60;
		if 35 > offsetX then
			offsetX = offsetX + 40;
		end
		if label:GetWidth() < timeBox:GetWidth() + 20 then
			offsetX = math.min(offsetX, label:GetX() - timeBox:GetWidth()/2);
		end
		timeBox:SetOffset(offsetX, label:GetY() + label:GetHeight() - 10);
	else
		local offsetX = label:GetX() + txt:GetWidth() - 60;
		if 35 > offsetX then
			offsetX = offsetX + 40;
		end
		timeBox:SetOffset(offsetX, label:GetY() + label:GetHeight() - 10);
	end
end

--************************************************
-- 保存処理
--************************************************
function CHATEXTENDS_SAVE_CHAT()
	local groupboxname = "chatgbox_TOTAL";
	local chatframe = ui.GetFrame("chatframe");
	local groupbox = GET_CHILD(chatframe,groupboxname);
	local cnt = groupbox:GetChildCount();
	local clusterinfo = nil;

	-- ファイル名に使用する時間
	local time = geTime.GetServerSystemTime();
	local year = string.format("%04d",time.wYear);
	local month = string.format("%02d",time.wMonth);
	local day = string.format("%02d",time.wDay);
	local hour = string.format("%02d",time.wHour);
	local min = string.format("%02d",time.wMinute);
	local sec = string.format("%02d",time.wSecond);

	-- ファイル名は YYYYMMDD_HHMISS_キャラ名.txt
	local logfile=string.format("savechat_%s%s%s_%s%s%s_%s.txt", year,month,day,hour,min,sec,GETMYPCNAME());

	-- ファイル書き込みモード
	file,err = io.open(g.SAVE_DIR.."/"..logfile, "w")
	if err then
		if option.GetCurrentCountry()=="Japanese" then
			ui.SysMsg("チャットの保存に失敗しました(フォルダがない？)");
		else
			ui.SysMsg("SAVE CHAT FAILED.(NOT DIRECTORY?)");
		end
	else
		for i = 0 , cnt - 2 do
			clusterinfo = session.ui.GetChatMsgInfo(groupboxname, i);
			file:write(CHATEXTENDS_GET_MSGBODY(clusterinfo,clusterinfo:GetMsg()));
		end
		file:close();
		if option.GetCurrentCountry()=="Japanese" then
			ui.SysMsg("チャットを保存しました");
		else
			ui.SysMsg("SAVE CHAT");
		end
	end
end

--************************************************
-- ファイル書き込めるか確認
--************************************************
function CHATEXTENDS_CHECK_DIR(dirname)
	file,err = io.open(dirname.."/test.tmp", "w")
	if err then
		return false
	else
		file:close();
		os.remove(dirname.."/test.tmp");
		return true
	end
end

--************************************************
-- ファイル出力内容
--************************************************
function CHATEXTENDS_GET_MSGBODY(clusterinfo,msgbody)
	local logbody="";
	local tempstr="";
	logbody=string.format("%s %s %s:%s{nl}", clusterinfo:GetTimeStr(), CHATEXTENDS_GET_MSGTYPE_TXT(clusterinfo:GetMsgType()),clusterinfo:GetCommanderName(),msgbody);
	logbody=string.gsub(logbody,"{nl}", "\n");
--	logbody=string.gsub(logbody,"{.-}", "");

	-- stinrg.gsub内で直接dictionary.ReplaceDicIDInCompStr("%1")とやったが使えなかった
	-- ので、一時変数に入れる
--	tempstr=string.match(logbody, "(@dicID.+\*\^)");
--	if tempstr ~= nil then
--		tempstr = dictionary.ReplaceDicIDInCompStr(tempstr);
--		logbody=string.gsub(logbody,"(@dicID.+\*\^)", tempstr);
--	end
	return logbody;
end

--************************************************
-- ファイル出力時のメッセージタイプの文言
--************************************************
function CHATEXTENDS_GET_MSGTYPE_TXT(msgType)
	if option.GetCurrentCountry()=="Japanese" then
		if (msgType == "friendmem") or (msgType == "guildmem") then
			return "[システム　]";
		elseif msgType == "Normal" then
			return "[一般　　　]";
		elseif msgType == "Shout" then
			return "[シャウト　]";
		elseif msgType == "Party" then
			return "[パーティー]";
		elseif msgType == "Guild" then
			return "[ギルド　　]";
		elseif msgType == "Notice" then
			return "[お知らせ　]";
		elseif msgType == "System" then
			return "[システム　]";
		else
			return "[ささやき　]";
		end
	else
		return "["..msgType.."]";
	end
end

--************************************************
-- サイズ変更
--************************************************
function CHATEXTENDS_CHAT_SET_FONTSIZE_N_COLOR(chatframe) 

	if chatframe == nil then
		return;
	end

	local offsetX = chatframe:GetUserConfig("CTRLSET_OFFSETX");
	local targetSize = GET_CHAT_FONT_SIZE();
	local count = chatframe:GetChildCount();
	for  i = 0, count-1 do 
		local groupBox  = chatframe:GetChildByIndex(i);
		local childName = groupBox:GetName();

		if string.sub(childName, 1, 9) == "chatgbox_" then
			if groupBox:GetClassName() == "groupbox" then
				groupBox = AUTO_CAST(groupBox);
				local beforeHeight = 1;
				local lastChild = nil;
				local ctrlSetCount = groupBox:GetChildCount();
				for j = 0 , ctrlSetCount - 1 do
					local chatCtrl = groupBox:GetChildByIndex(j);
					if chatCtrl:GetClassName() == "controlset" then
						local label = chatCtrl:GetChild('bg');
						if g.settings.BALLON_FLG then
							local txt = GET_CHILD(label, "text", "ui::CRichText");

							if txt == nil then
								txt = GET_CHILD(chatCtrl, "text", "ui::CRichText");
							end;	

							local msgString = CHAT_TEXT_CHAR_RESIZE(txt:GetTextByKey("text"), targetSize);
							txt:SetTextByKey("text", msgString);
							txt:SetTextByKey("size", targetSize);
							local timeBox = GET_CHILD(chatCtrl, "timebox");
							CHATEXTENDS_RESIZE_CHAT_CTRL_BALLON(chatCtrl, label, txt, timeBox)
						else

							local txt = GET_CHILD(chatCtrl, "text", "ui::CRichText");
							local msgString = CHAT_TEXT_CHAR_RESIZE(txt:GetTextByKey("text"), targetSize);
							
							
							local roomid = txt:GetUserValue("ROOM_ID")

							if roomid ~= "None" then

								local colorType = session.chat.GetRoomConfigColorType(roomid)
								local colorCls = GetClassByType("ChatColorStyle", colorType)

								if colorCls ~= nil then
									fontStyle = "{#"..colorCls.TextColor.."}{b}{ol}"
									txt:SetTextByKey("font", fontStyle);
								end
							end

							txt:SetTextByKey("text", msgString);
							txt:SetTextByKey("size", targetSize);	
							local timeBox = GET_CHILD(chatCtrl, "time");
							RESIZE_CHAT_CTRL(chatframe, chatCtrl, label, txt, timeBox, offsetX)
						end
							
						beforeHeight = chatCtrl:GetY() + chatCtrl:GetHeight();
						lastChild = chatCtrl;
					end
				end

				GBOX_AUTO_ALIGN(groupBox, 0, 0, 0, true, false);
				if lastChild ~= nil then
					local afterHeight = lastChild:GetY() + lastChild:GetHeight();					
					local heightRatio = afterHeight / beforeHeight;
					
					groupBox:UpdateData();
					groupBox:SetScrollPos(groupBox:GetCurLine() * (heightRatio * 1.1));
				end
			end
		end
	end

    if string.find(chatframe:GetName(),"chatpopup") ~= nil then
           CHATPOPUP_FOLD_BY_SIZE(chatframe)
    end

	chatframe:Invalidate();

end
