--Sparkle Arcadia Sanctuary (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--① 발동시 효과 : 덱에서 "스파클 아르카디아" 몬스터 1장 패에 넣기
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- 이 카드명의 카드는 1턴에 1장만 발동 가능
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--② 자신의 싱크로 몬스터 공격력 상승 (묘지의 스파클 아르카디아 카드 종류 x100)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	
	--③ 스파클 아르카디아 몬스터가 묘지로 보내졌을 경우 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

------------------------------------------------
--① 발동시 처리: 덱에서 스파클 아르카디아 몬스터 1장 패에 넣기
------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

------------------------------------------------
--② 공격력 상승 : 묘지의 스파클 아르카디아 카드 종류 수 ×100
------------------------------------------------
function s.atktg(e,c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(Card.IsSetCard,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil,0x760)
	-- 종류 수 계산 (같은 이름 제외)
	local count=g:GetClassCount(Card.GetCode)
	return count*100
end

------------------------------------------------
--③ 묘지로 보내졌을 경우: 스파클 아르카디아 몬스터 1장 특수 소환
------------------------------------------------
function s.spfilter(c,tp)
	return c:IsSetCard(0x760) and c:IsMonster() and c:IsControler(tp)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spfilter,1,nil,tp)
end
function s.tgfilter(c,e,tp)
	return c:IsSetCard(0x760) and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.tgfilter(chkc,e,tp) end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
