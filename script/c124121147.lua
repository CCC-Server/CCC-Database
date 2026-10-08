--베릴의 마도서
local s,id=GetID()
function s.initial_effect(c)
	--②: 필드의 마법 카드 / 몬스터 카드를 대상으로 하고, 그에 대응하는 효과를 발동
	--(이 카드명의 이하의 효과는 각각 1턴에 1번밖에 사용할 수 없다 → "현람한 현현"처럼 플레이어 플래그로 관리)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
	--이 카드는 패에서 공개되어 있는 한 상대 턴에도 발동할 수 있다
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
	--①: 자신 / 상대가 발동한 마법 카드의 효과 처리시에, 패의 이 카드를 턴 종료시까지 공개할 수 있다
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_HAND)
	e3:SetCondition(s.pubcon)
	e3:SetOperation(s.pubop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_SPELLBOOK}
s.listed_names={id}
--패에서 공개되어 있는 동안
function s.handcon(e)
	return e:GetHandler():IsPublic()
end
--①
function s.pubcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_SPELL)
		and not e:GetHandler():IsPublic()
end
function s.pubop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,2)) then return end
	Duel.Hint(HINT_CARD,0,id)
	--턴 종료시까지 공개 ("브레이크 오브 더 월드" 참조)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_PUBLIC)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	c:RegisterEffect(e1)
end
--②
--●마법 카드 : 필드의 앞면 표시 마법 카드
function s.spfilter(c)
	return c:IsFaceup() and c:IsSpell()
end
--●몬스터 카드 : 필드의 몬스터
function s.mfilter(c)
	return c:IsMonster() and c:IsLocation(LOCATION_MZONE)
end
function s.thfilter1(c)
	return c:IsSetCard(SET_SPELLBOOK) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thfilter2(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT|ATTRIBUTE_DARK) and c:IsRace(RACE_SPELLCASTER)
		and c:IsLevelAbove(5) and c:IsAbleToHand()
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then
		local op=e:GetLabel()
		if op==1 then return chkc:IsOnField() and chkc~=c and s.spfilter(chkc) end
		return chkc:IsLocation(LOCATION_MZONE) and s.mfilter(chkc)
	end
	local b1=not Duel.HasFlagEffect(tp,id)
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c)
		and Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
	local b2=not Duel.HasFlagEffect(tp,id+1)
		and Duel.IsExistingTarget(s.mfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
		and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)})
	e:SetLabel(op)
	e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DISABLE)
	local g
	if op==1 then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,c)
	else
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE|PHASE_END,0,1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		g=Duel.SelectTarget(tp,s.mfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	local thf=(op==1) and s.thfilter1 or s.thfilter2
	--덱에서 1장을 패에 넣는다
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,thf,tp,LOCATION_DECK,0,1,1,nil)
	if #g==0 or Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,g)
	--그 후, 대상 카드의 효과를 무효로 할 수 있다
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsNegatable()
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.BreakEffect()
		tc:NegateEffects(c,nil,true)
	end
end
