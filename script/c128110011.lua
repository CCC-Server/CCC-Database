--유네티스 카이로코라
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 설정
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,2)
	
	--소재 체크 (융합 몬스터 소재 여부 확인용)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_MATERIAL_CHECK)
	e0:SetValue(s.matcheck)
	c:RegisterEffect(e0)

	--①: 필드 바운스 후 패 일반 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1) -- 소프트 턴 제약
	e1:SetTarget(s.nsumtg)
	e1:SetOperation(s.nsumop)
	c:RegisterEffect(e1)
	
	--②: 몬스터 효과 무효 후 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1) -- 소프트 턴 제약 (조건에 따라 턴당 1회)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
	
	--③: 파괴 시 엑스트라 덱 P몬스터 서치
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc80}

-- [링크 소재]: 링크 몬스터 이외의 "유네티스" 몬스터 2장
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0xc80,lc,sumtype,tp) and not c:IsType(TYPE_LINK,lc,sumtype,tp)
end

-- [소재 체크]: 융합 몬스터를 소재로 했는지 확인
function s.matcheck(e,c)
	local g=c:GetMaterial()
	if g:IsExists(Card.IsType,1,nil,TYPE_FUSION) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD-RESET_TOHAND-RESET_TOGRAVE,0,1)
	end
end

-- [효과 ①]
function s.thfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.nsfilter(c)
	return c:IsSetCard(0xc80) and c:IsSummonable(true,nil)
end
function s.nsumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,0,0)
end
function s.nsumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #sg>0 then
			Duel.Summon(tp,sg:GetFirst(),true,nil)
		end
	end
end

-- [효과 ②]
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 자신 턴이거나, 융합 몬스터를 소재로 했다면 발동 가능
	local turn_cond = (Duel.GetTurnPlayer()==tp) or (c:GetFlagEffect(id)>0)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev) and turn_cond
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xc80) and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_PZONE)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_PZONE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_PZONE)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_PZONE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

-- [효과 ③]
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_BATTLE+REASON_EFFECT)
end
function s.searchfilter(c)
	return c:IsSetCard(0xc80) and c:IsType(TYPE_PENDULUM) and c:IsFaceup() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.searchfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.searchfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end