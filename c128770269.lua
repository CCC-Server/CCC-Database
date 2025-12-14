--Spellcraft Witch (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 상대가 스펠크래프트 몬스터의 효과에 체인했을 경우, 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 마력 카운터 제거 → 상대 몬스터 전멸
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③ 자신 턴에 특수 소환 성공 시 묘지의 스펠크래프트 카드 회수
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

---------------------------------------------------------------
--① 상대가 "스펠크래프트" 몬스터의 효과에 체인했을 경우
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and rc:IsSetCard(0x761) and rc:IsType(TYPE_MONSTER)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------------------------------
--② 마력 카운터 제거 → 상대 몬스터 파괴
function s.cauldronfilter(c)
	return c:IsFaceup() and c:IsCode(128770286)
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.cauldronfilter,tp,LOCATION_SZONE,0,nil)
	if chk==0 then 
		return g:IsExists(Card.IsCanRemoveCounter,1,nil,tp,0x1,1,REASON_COST)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=g:Select(tp,1,1,nil):GetFirst()
	Duel.HintNumber(tp,13)
	local maxc=math.min(tc:GetCounter(0x1),13)
	Duel.Hint(HINT_NUMBER,tp,math.min(13,maxc))
	local count=Duel.AnnounceNumber(tp,table.unpack({1,2,3,4,5,6,7,8,9,10,11,12,13}))
	if count>maxc then count=maxc end
	e:SetLabel(count)
	tc:RemoveCounter(tp,0x1,count,REASON_COST)
end
function s.desfilter(c,lv)
	return c:IsFaceup() and (c:IsLevelBelow(lv) or c:IsRankBelow(lv))
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local lv=e:GetLabel()
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_MZONE,1,nil,lv) end
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,lv)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local lv=e:GetLabel()
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,lv)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

---------------------------------------------------------------
--③ 자신 턴에 특수 소환되었을 경우, 묘지의 스펠크래프트 카드 1장 회수
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp)
end
function s.thfilter(c)
	return c:IsSetCard(0x761) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
