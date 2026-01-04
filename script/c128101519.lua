--마린세스 스노우 화이트
--Marincess Snow White
local s,id=GetID()
function s.initial_effect(c)
	--①: 패에서 보여주고 발동. 배틀오션 배치 후 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--②: 묘지에서 제외하고 파괴 + 함정 서치 (타이밍: ~때)
	--효과 대상으로 선택되었을 때
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BECOME_TARGET)
	-- [수정] EFFECT_FLAG_DELAY를 제거하여 '때'로 구현
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP) 
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.descon1)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	--공격 대상으로 선택되었을 때
	local e3=e2:Clone()
	e3:SetCode(EVENT_BE_BATTLE_TARGET)
	e3:SetCondition(s.descon2)
	c:RegisterEffect(e3)
end

-- 배틀오션 카드 번호 (사용자 제공 번호 사용)
local CARD_BATTLE_OCEAN = 91027843

s.listed_names={CARD_BATTLE_OCEAN}
s.listed_series={SET_MARINCESS}

-- ①번 효과 로직
function s.fieldfilter(c)
	return c:IsCode(CARD_BATTLE_OCEAN) and not c:IsForbidden()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.fieldfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc then
		-- 덱에서 배틀오션을 필드에 놓음
		if Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true) then
			-- 그 후 특수 소환
			local c=e:GetHandler()
			if c:IsRelateToEffect(e) then
				Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-- ②번 효과 로직 (상대 효과의 대상이 되었을 때)
function s.descon1(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end -- 상대의 효과일 것
	return eg:IsExists(function(c) return c:IsControler(tp) and c:IsFaceup() and c:IsSetCard(SET_MARINCESS) end,1,nil)
end

-- ②번 효과 로직 (상대 공격의 대상이 되었을 때)
function s.descon2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttackTarget()
	return tc and tc:IsControler(tp) and tc:IsFaceup() and tc:IsSetCard(SET_MARINCESS)
end

-- 파괴 및 서치 대상 확인
function s.thfilter(c)
	return c:IsSetCard(SET_MARINCESS) and c:IsTrap() and c:IsAbleToHand()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
		-- 파괴 후 덱에서 마린세스 함정 서치 가능
		local sg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sc=sg:Select(tp,1,1,nil)
			Duel.SendtoHand(sc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sc)
		end
	end
end