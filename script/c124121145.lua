--시오르의 마도서
local s,id=GetID()
function s.initial_effect(c)
	--●1장: 필드의 앞면 표시 몬스터 1장의 공격력 / 수비력을 0으로 한다
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(TIMING_DAMAGE_STEP,TIMING_DAMAGE_STEP|TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition1)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	e1:SetLabel(1)
	c:RegisterEffect(e1)
	--●2장: 필드 / 묘지의 몬스터 1장을 고르고, 이 턴에 그 몬스터 및 원래의 카드명이 같은 몬스터의 효과를 무효
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.condition)
	e2:SetCost(s.cost)
	e2:SetTarget(s.target2)
	e2:SetOperation(s.activate2)
	e2:SetLabel(2)
	c:RegisterEffect(e2)
	--●3장 이상: 되돌린 카드 3장당 1장까지, 필드의 카드를 덱으로 되돌린다
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_ACTIVATE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e3:SetCondition(s.condition)
	e3:SetCost(s.cost)
	e3:SetTarget(s.target3)
	e3:SetOperation(s.activate3)
	e3:SetLabel(3)
	c:RegisterEffect(e3)
end
s.listed_series={SET_SPELLBOOK}
--공통 : 자신 필드에 마법사족 몬스터가 존재할 경우
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_SPELLCASTER),tp,LOCATION_MZONE,0,1,nil)
end
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
	return s.condition(e,tp,eg,ep,ev,re,r,rp) and aux.StatChangeDamageStepCondition()
end
--공통 코스트 : 묘지 / 제외 상태의 "마도서" 마법 카드를 덱으로 되돌린다
--1장 모드는 정확히 1장, 2장 모드는 정확히 2장, 3장 이상 모드는 3장 이상 임의의 수
function s.cfilter(c)
	return c:IsSetCard(SET_SPELLBOOK) and c:IsSpell() and (c:IsFaceup() or not c:IsLocation(LOCATION_REMOVED))
		and c:IsAbleToDeckAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local mode=e:GetLabel()
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.cfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,nil)
	if chk==0 then return #g>=mode end
	local min,max=mode,mode
	if mode==3 then max=#g end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local sg=g:Select(tp,min,max,nil)
	local rg,hg=sg:Split(Card.IsLocation,nil,LOCATION_REMOVED)
	if #hg>0 then Duel.HintSelection(hg) end
	if #rg>0 then Duel.HintSelection(rg) end
	Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_COST)
	local ct=Duel.GetOperatedGroup():FilterCount(Card.IsLocation,nil,LOCATION_DECK|LOCATION_EXTRA)
	--모드(1/2/3)와 실제로 되돌린 장수를 함께 기록
	e:SetLabel(mode,ct)
end
--●1장
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
end
function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil):GetFirst()
	if not tc then return end
	Duel.HintSelection(tc)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetValue(0)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
	tc:RegisterEffect(e2)
end
--●2장
function s.disfilter(c)
	return c:IsMonster() and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.disfilter,tp,LOCATION_MZONE|LOCATION_GRAVE,LOCATION_MZONE|LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
end
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.disfilter),tp,LOCATION_MZONE|LOCATION_GRAVE,LOCATION_MZONE|LOCATION_GRAVE,1,1,nil):GetFirst()
	if not tc then return end
	Duel.HintSelection(tc)
	local c=e:GetHandler()
	local code=tc:GetOriginalCodeRule()
	--필드의 해당 몬스터의 효과 무효
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetTarget(s.distg)
	e1:SetLabel(code)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--필드 이외(패 / 묘지 등)에서 발동한 해당 몬스터의 효과 무효
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetCondition(s.discon)
	e2:SetOperation(s.disop)
	e2:SetLabel(code)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
function s.distg(e,c)
	local code=e:GetLabel()
	local code1,code2=c:GetOriginalCodeRule()
	return code1==code or code2==code
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	local code1,code2=re:GetHandler():GetOriginalCodeRule()
	return re:IsMonsterEffect() and (code1==code or code2==code)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.NegateEffect(ev)
end
--●3장 이상
function s.target3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end
function s.activate3(e,tp,eg,ep,ev,re,r,rp)
	local _,rct=e:GetLabel()
	local ct=(rct or 0)//3
	if ct<=0 then return end
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,c)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
