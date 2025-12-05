--종이 비행기 아코이츠
local s,id=GetID()
function s.initial_effect(c)
	-- 기본 정보
	c:EnableReviveLimit()
	-- 융합 소환 조건: "Paper Plane - Aitsu" + 1 "Paper Plane" 몬스터
	Fusion.AddProcMix(c,true,true,128101435,aux.FilterBoolFunction(Card.IsSetCard,0xc53))

	s.listed_series={0xc53}
	s.listed_names={128101435}

	--------------------------------
	-- ※ 전역 플래그: 상대가 "이번 턴에 카드 효과를 발동했는지" 체크
	--------------------------------
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAINING)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end

	--------------------------------
	-- ① 융합 소환 성공시 서치
	--   기본: GY의 "Paper Plane" 카드 1장 패로
	--   만약 "이번 턴에 상대가 카드 효과를 발동한 적이 있다면"
	--   → 대신 덱에서 "Paper Plane" 카드 1장 패로
	-- (이 카드명의 ① 효과는 1턴에 1번)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.thcon1)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.thtg1)
	e1:SetOperation(s.thop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 퀵: 묘지의 유니온 몬스터 1장을 이 카드에 장착 마법으로 장착
	--	  그 후, 상대 필드의 몬스터 1장을 제외
	-- (이 카드명의 ② 효과는 1턴에 1번)
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

--------------------------------
-- 전역: 이번 턴에 어느 플레이어가 카드 효과를 발동했는지 플래그
--------------------------------
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	-- ep: 그 체인의 효과를 발동한 플레이어
	Duel.RegisterFlagEffect(ep,id,RESET_PHASE+PHASE_END,0,1)
end

--------------------------------
-- ① 융합 소환 성공시 서치
--------------------------------
function s.thcon1(e,tp,eg,ep,ev,re,r,rp)
	-- 융합 소환으로 소환된 경우에만
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.thfilter1(c)
	return c:IsSetCard(0xc53) and c:IsAbleToHand()
end
function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_GRAVE+LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_DECK)
end
function s.thop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local opp=1-tp
	local opp_activated=Duel.GetFlagEffect(opp,id)>0 -- 이번 턴 상대가 카드 효과 발동한 적 있는지
	local loc=0
	-- 우선순위: 조건이 만족하면 덱, 아니면 묘지
	if opp_activated and Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil) then
		loc=LOCATION_DECK
	elseif Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_GRAVE,0,1,nil) then
		loc=LOCATION_GRAVE
	else
		return
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,loc,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------
-- ② 유니온 장착 + 상대 몬스터 제외
--------------------------------
function s.eqfilter(c)
	-- 묘지의 유니온 몬스터
	return c:IsType(TYPE_MONSTER) and c:IsType(TYPE_UNION)
		and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp)
			and s.eqfilter(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,LOCATION_MZONE)
end
function s.eqlimit(e,c)
	-- 이 장착 카드는 지정된 몬스터(아코이츠)에만 장착 가능
	return c==e:GetLabelObject()
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	-- 묘지의 유니온 몬스터를 이 카드에 장착
	if not Duel.Equip(tp,tc,c,true) then return end

	-- 타입을 "장착 마법 카드"로 취급 (SPELL + EQUIP)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CHANGE_TYPE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
	e0:SetValue(TYPE_SPELL+TYPE_EQUIP)
	tc:RegisterEffect(e0)

	-- 장착 제한 (이 몬스터에만)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	e1:SetValue(s.eqlimit)
	e1:SetLabelObject(c)
	tc:RegisterEffect(e1)

	-- 그 후, 상대 필드의 몬스터 1장 제외
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local rg=g:Select(tp,1,1,nil)
		Duel.HintSelection(rg)
		Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
	end
end
