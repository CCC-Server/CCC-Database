--종이 비행기-아이츠
local s,id=GetID()
function s.initial_effect(c)
	-- "Paper Plane" 카드군
	s.listed_series={0xc53}

	--① 컨트롤러 필드에 몬스터가 없거나, "Paper Plane" 몬스터만 있을 때 릴리스 없이 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SUMMON_PROC)
	e1:SetCondition(s.ntcon)
	e1:SetCountLimit(1,{id,0}) -- ① 하드 OPT
	c:RegisterEffect(e1)

	--② 일반 소환/특수 소환 성공시, 덱/묘지에서 "Paper Plane" 몬스터 1장을
	--   이 카드에 "장착 마법 카드 취급"으로 장착
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1}) -- ② 하드 OPT
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	--③ 메인 페이즈에, 마법/함정 존의 "장착 카드가 된 몬스터" 1장을 특수 소환 (퀵)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e4:SetCountLimit(1,{id,2}) -- ③ 하드 OPT
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

--------------------------------
-- ① 릴리스 없이 일반 소환
--------------------------------
function s.mfilter(c)
	-- "Paper Plane"이 아닌 몬스터
	return not c:IsSetCard(0xc53)
end
function s.ntcon(e,c,minc)
	if c==nil then return true end
	local tp=c:GetControler()
	-- 레벨 5 이상, 추가 릴리스가 요구되는 소환이 아니어야 함
	if c:GetLevel()<=4 or minc>0 then return false end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
	local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	-- 몬스터가 0장이거나, 자신 필드의 몬스터가 전부 "Paper Plane"이면 OK
	return #g==0 or not g:IsExists(s.mfilter,1,nil)
end

--------------------------------
-- ② 덱/묘지에서 "Paper Plane" 몬스터를
--    이 카드에 장착(장착 마법 카드 취급)
--------------------------------
function s.eqfilter(c)
	return c:IsSetCard(0xc53) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.eqlimit(e,c)
	-- 이 장착 카드는 해당 몬스터(아이츠)에만 장착 가능
	return c==e:GetLabelObject()
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.eqfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	-- 몬스터를 이 카드에 장착 (이 시점에서 이미 '장착 카드 취급'이 됨)
	if Duel.Equip(tp,tc,c,true) then
		-- 장착 제한: 이 카드에만 장착
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(c)
		tc:RegisterEffect(e1)
	end
end

--------------------------------
-- ③ 장착 몬스터 특수 소환 (퀵)
--------------------------------
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 메인 페이즈에만 발동 가능
	return Duel.IsMainPhase()
end
function s.spfilter(c,e,tp)
	-- 마함존에 존재하면서, 원래는 몬스터였고,
	-- 실제로 "장착"되어 있는 카드만 대상으로
	return c:IsFaceup()
		and c:IsLocation(LOCATION_SZONE)
		and c:GetOriginalType()&TYPE_MONSTER~=0
		and c:GetEquipTarget()~=nil
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp)
			and s.spfilter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_SZONE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_SZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
end
