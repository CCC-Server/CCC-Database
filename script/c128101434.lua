--World Guardian – Only One (Continuous Trap prototype)
local s,id=GetID()
function s.initial_effect(c)
	------------------------------------
	-- Activate
	------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	------------------------------------
	-- (1) 메인 페이즈: 월가 파괴 → 다른 속성 월가 특소 (+ 상대 2회 이상 특소 시 제외)
	------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)            -- 함정이니 프리체인 퀵
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)                     -- (1) 효과 턴 1회
	e1:SetCondition(s.spcon_main)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	------------------------------------
	-- 상대 특소 횟수 체크용 글로벌 (1번 효과 "2번 이상 특소" 체크용)
	------------------------------------
	if not s.global_check_ss then
		s.global_check_ss=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

	------------------------------------
	-- (2) 센서만별 스타일 + 소환 제한
	------------------------------------
	-- 글로벌 조정 효과 (There Can Be Only One 방식)
	aux.GlobalCheck(s,function()
		s.lastFieldId={}
		s.lastFieldId[0]=nil
		s.lastFieldId[1]=nil
		local ge=Effect.GlobalEffect()
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		ge:SetCode(EVENT_ADJUST)
		ge:SetOperation(s.adjustop)
		Duel.RegisterEffect(ge,0)
	end)

	-- 소환 / 특소 / 반전 소환 제한 (센서만별/어전시합 스타일)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCode(EFFECT_FORCE_SPSUMMON_POSITION)
	e3:SetTargetRange(1,1)
	e3:SetTarget(s.sumlimit)
	e3:SetValue(POS_FACEDOWN)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e4)
	local e5=e3:Clone()
	e5:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e5)

	-- 자기 자신을 뒤집는 코스트 효과 발동 제한 (센서만별 / 어전시합 공통 패턴)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetCode(EFFECT_CANNOT_ACTIVATE)
	e6:SetRange(LOCATION_SZONE)
	e6:SetTargetRange(1,1)
	e6:SetValue(s.aclimit)
	c:RegisterEffect(e6)
end

----------------------------------------------------------
-- 공통: 상대 특소 횟수 카운트 (1번 효과용)
----------------------------------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	while tc do
		local p=tc:GetSummonPlayer()
		Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
		tc=eg:GetNext()
	end
end

----------------------------------------------------------
-- (1) 메인 페이즈 조건
----------------------------------------------------------
function s.spcon_main(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

-- 내가 컨트롤하는 "World Guardian" 몬스터
function s.wgmon_filter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER) and c:IsDestructable()
end

-- 특소할 "World Guardian" 몬스터 (다른 원래 속성)
function s.spfilter(c,e,tp,orig_attr)
	return c:IsSetCard(0xc52) and c:IsType(TYPE_MONSTER)
		and c:GetOriginalAttribute()~=orig_attr
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.wgmon_filter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.wgmon_filter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.wgmon_filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	-- 파괴할 몬스터의 원래 속성 저장
	local orig_attr=tc:GetOriginalAttribute()

	-- ① 지정한 "World Guardian" 몬스터 파괴
	if Duel.Destroy(tc,REASON_EFFECT)==0 then return end

	-- ② 다른 원래 속성을 가진 "World Guardian" 몬스터를 패/덱/묘지에서 특수 소환
	if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,orig_attr) then
		return
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,orig_attr)
	if #sg==0 then return end
	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- ③ 상대가 이번 턴에 몬스터를 2장 이상 특소했다면, "You can"으로 제외
	if Duel.GetFlagEffect(1-tp,id)>=2
		and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local rg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #rg>0 then
			Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
		end
	end
end

----------------------------------------------------------
-- (2) 센서만별 스타일 + 소환 제한
--     조건: "이 카드가 앞면" + "그 컨트롤러가 월가 카드를 컨트롤"
----------------------------------------------------------
function s.wgcard_filter(c)
	return c:IsFaceup() and c:IsSetCard(0xc52)
end

-- 이 월가 함정 효과가 실제로 켜져 있는지 (둘 중 아무 쪽이든)
function s.active_trap_filter(c)
	local tp=c:GetControler()
	return c:IsFaceup() and c:IsCode(id)
		and Duel.IsExistingMatchingCard(s.wgcard_filter,tp,LOCATION_ONFIELD,0,1,nil)
end

local function flood_active()
	return Duel.IsExistingMatchingCard(s.active_trap_filter,0,LOCATION_SZONE,LOCATION_SZONE,1,nil)
end

function s.fidfilter(c,fid)
	return c:GetFieldID()>fid
end

-- 조정: 이미 나와 있는 몬스터들 중, 같은 종족이 2장 이상이면 1장만 남기고 나머지 묘지로
function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
	local phase=Duel.GetCurrentPhase()
	if (phase==PHASE_DAMAGE and not Duel.IsDamageCalculated()) or phase==PHASE_DAMAGE_CAL then return end
	-- 월가 카드 + 이 함정이 앞면으로 존재하는 쪽이 아무도 없으면 작동 X
	if not flood_active() then
		s.lastFieldId[0]=nil
		s.lastFieldId[1]=nil
		return
	end
	local sg=Group.CreateGroup()
	for p=0,1 do
		local g=Duel.GetMatchingGroup(Card.IsFaceup,p,LOCATION_MZONE,0,nil)
		if #g==0 then
			s.lastFieldId[p]=nil
		else
			local race=1
			local update_fid=false
			while (RACE_ALL & race)~=0 do
				local rg=g:Filter(Card.IsRace,nil,race)
				if s.lastFieldId[p] then
					local forced
					forced,rg=rg:Split(s.fidfilter,nil,s.lastFieldId[p])
					if #rg==0 then
						rg=forced
						update_fid=true
					else
						sg:Merge(forced)
					end
				end
				local rc=#rg
				if rc>1 then
					Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TOGRAVE)
					sg:Merge(rg:Select(p,rc-1,rc-1,nil))
				end
				race=race<<1
			end
			if update_fid or not s.lastFieldId[p] then
				local maxg,maxid=g:Sub(sg):GetMaxGroup(Card.GetFieldID)
				s.lastFieldId[p]=maxid
			end
		end
	end
	local p=e:GetHandlerPlayer()
	local g1,g2=Group.CreateGroup(),Group.CreateGroup()
	local readjust=false
	if #sg>0 then
		g1,g2=sg:Split(Card.IsControler,nil,p)
	end
	if #g1>0 then
		Duel.SendtoGrave(g1,REASON_RULE,PLAYER_NONE,p)
		readjust=true
	end
	if #g2>0 then
		Duel.SendtoGrave(g2,REASON_RULE,PLAYER_NONE,1-p)
		readjust=true
	end
	if readjust then Duel.Readjust() end
end

----------------------------------------------------------
-- 소환 / 특소 / 반전 소환 제한 (센서만별/어전시합 스타일)
----------------------------------------------------------
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp)
	-- 월가 함정 효과가 켜져 있지 않으면 소환 제한 X
	if not flood_active() then return false end
	local tp=sump
	if targetp then tp=targetp end
	-- 이미 같은 종족의 앞면 몬스터를 컨트롤 중이면 소환 불가
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,c:GetRace()),tp,LOCATION_MZONE,0,1,c)
end

----------------------------------------------------------
-- 자기 자신을 뒤집는 코스트 효과 발동 제한
----------------------------------------------------------
function s.aclimit(e,re,tp)
	-- 월가 함정 효과가 켜져 있지 않으면 제한 X
	if not flood_active() then return false end
	-- 자신을 뒤집는 코스트 + 이미 같은 종족의 몬스터 컨트롤 중이면 발동 불가
	return re:HasSelfChangePositionCost()
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,re:GetHandler():GetRace()),tp,LOCATION_MZONE,0,1,nil)
end
