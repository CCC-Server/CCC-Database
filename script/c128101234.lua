--Salamangreat Custom
local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	-- "①의 방법에 의한 특수 소환은 1턴에 1번" → OATH 처리
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 덱 1장 '코스트'로 묘지 → 그와 다른 이름 1장 패에
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH) -- 코스트로 GY 보내므로 카테고리에서 TOGRAVE 제거
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.thcost)       -- ★ 코스트로 덱에서 보내기
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_SALAMANGREAT}

--------------------------------------
--① 패에서 특수 소환
--------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		--이 턴 동안 불속성 몬스터밖에 특수 소환 불가
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(function(e,c) return not c:IsAttribute(ATTRIBUTE_FIRE) end)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

--------------------------------------
--② 코스트로 GY → 다른 이름 서치
--------------------------------------
-- 코스트로 보낼 카드(덱)
function s.tgfilter(c)
	return c:IsSetCard(SET_SALAMANGREAT) and c:IsAbleToGraveAsCost()
end
-- 서치 대상(덱) : 코스트로 보낸 코드와 다른 이름
function s.thfilter(c,code)
	return c:IsSetCard(SET_SALAMANGREAT) and (code==nil or not c:IsCode(code)) and c:IsAbleToHand()
end

-- ★ 코스트: 덱에서 "샐러맨그레이트" 1장 GY로 (REASON_COST), 그리고 그 코드 저장
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	e:SetLabel(0)
	if tc then
		local code=tc:GetCode()
		e:SetLabel(code) -- 이후 타겟/오퍼레이션에서 다른 이름을 강제
		Duel.SendtoGrave(tc,REASON_COST)
	end
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local code=e:GetLabel()
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,code)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil,code)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end
