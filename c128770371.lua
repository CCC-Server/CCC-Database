-- Spell Librarian – Field Spell (0x768)
local s,id=GetID()
local SET_LIB=0x768

function s.initial_effect(c)

	-----------------------------------------------------
	-- 0. 기본 발동 조건
	-----------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCondition(s.actcon)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e0:SetOperation(s.actop)
	c:RegisterEffect(e0)

	-----------------------------------------------------
	-- 2. "Spell Librarian" Spell 발동 → 다른 Type Spell 세트
	-----------------------------------------------------
-- ②: "Spell Librarian" 마법 카드 발동되었을 때, 타입 다른 마법 1장 셋트
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,1))
e2:SetCategory(CATEGORY_SEARCH)
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_CHAIN_SOLVED) -- ✅ 체인 해석 완료 후 트리거
e2:SetRange(LOCATION_FZONE)
e2:SetProperty(EFFECT_FLAG_DELAY)
e2:SetCountLimit(1,{id,2})
e2:SetCondition(s.setcon2)
e2:SetTarget(s.settg2)
e2:SetOperation(s.setop2)
c:RegisterEffect(e2)


	-----------------------------------------------------
	-- 3. 카드가 세트될 때 → 마력카운터 4 제거 후 Quick 발동 허용
	-----------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SSET)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCondition(s.qcon)
	e3:SetOperation(s.qop)
	c:RegisterEffect(e3)
end

---------------------------------------------------------
-- 0. 발동 조건: Normal/Special Summon 하지 않은 턴
---------------------------------------------------------
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetActivityCount(tp,ACTIVITY_SUMMON)==0
		and Duel.GetActivityCount(tp,ACTIVITY_SPSUMMON)==0
end

---------------------------------------------------------
-- ① 발동시 처리: "Spell Librarian" Spell 1장 세트
---------------------------------------------------------
function s.libfilter(c)
	return c:IsSetCard(SET_LIB) and c:IsType(TYPE_SPELL) and c:IsSSetable()
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.libfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end

---------------------------------------------------------
-- ② Spell Librarian Spell 발동 체크
---------------------------------------------------------
function s.setcon2(e,tp,eg,ep,ev,re,r,rp)
	if not (re and re:IsHasType(EFFECT_TYPE_ACTIVATE)) then return false end
	local rc=re:GetHandler()
	return rc:IsControler(tp)
		and rc:IsType(TYPE_SPELL)
		and rc:IsSetCard(SET_LIB)
		and rc~=e:GetHandler() -- ✅ 이 카드 자신이 아닐 경우에만 발동
end
function s.filter2(c,used_type)
	return c:IsType(TYPE_SPELL)
		and c:IsSSetable()
		and s.get_spell_type(c)~=used_type
end

function s.difftypefilter(c,typ)
	return c:IsType(TYPE_SPELL)
		and not c:IsType(typ)
		and c:IsSSetable()
end
function s.get_spell_type(c)
	if c:IsType(TYPE_RITUAL) then return TYPE_RITUAL end
	if c:IsType(TYPE_QUICKPLAY) then return TYPE_QUICKPLAY end
	if c:IsType(TYPE_CONTINUOUS) then return TYPE_CONTINUOUS end
	if c:IsType(TYPE_EQUIP) then return TYPE_EQUIP end
	if c:IsType(TYPE_FIELD) then return TYPE_FIELD end
	return TYPE_NORMAL
end

function s.settg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if not re or not re:GetHandler() then return false end
	local rc = re:GetHandler()
	local used_type = s.get_spell_type(rc)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil,used_type)
	end
	Duel.SetOperationInfo(0,CATEGORY_SEARCH,nil,1,tp,LOCATION_DECK)
end

function s.setop2(e,tp,eg,ep,ev,re,r,rp)
	if not re or not re:GetHandler() then return end
	local used_type = s.get_spell_type(re:GetHandler())
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g = Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_DECK,0,1,1,nil,used_type)
	if #g > 0 then
		Duel.SSet(tp,g)
		Duel.ConfirmCards(1-tp,g)
	end
end

---------------------------------------------------------
-- ③ 카드 세트 시 → 마력카운터 4 제거 → Quick-Play 즉발 허용
---------------------------------------------------------
---------------------------------------------------------
-- ③ 카드 세트 시 → 카운터 4 이상일 때만 발동 + 제거 선택
---------------------------------------------------------
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	local sc=eg:GetFirst()
	return rp==tp and sc:IsType(TYPE_SPELL)
end

function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local sc = eg:GetFirst()
	if not sc or not sc:IsType(TYPE_SPELL) then return end

	-- Spell Librarian 지속/필드 포함 모든 앞면 Spell Librarian 카드 수집
	local group=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,SET_LIB),tp,LOCATION_ONFIELD,0,nil)

	-- 총 카운터 수 체크
	local total=0
	for tc in group:Iter() do
		total = total + tc:GetCounter(0x1)
	end
	if total < 4 then return end

	-- 제거 여부 묻기
	if not Duel.SelectYesNo(tp,aux.Stringid(id,3)) then return end

	-- 카운터 제거할 카드 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local sel=Duel.SelectMatchingCard(tp,aux.FaceupFilter(Card.IsSetCard,SET_LIB),tp,LOCATION_ONFIELD,0,1,#group,nil)

	-- 선택된 카드에서 총 4개 카운터 제거
	local need=4
	for tc in sel:Iter() do
		local rem = math.min(tc:GetCounter(0x1), need)
		tc:RemoveCounter(tp,0x1,rem,REASON_EFFECT)
		need = need - rem
		if need <= 0 then break end
	end

	-- Quick-Play Spell 즉시 발동 가능 처리
	if sc:IsType(TYPE_QUICKPLAY) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sc:RegisterEffect(e1)
	end
end


