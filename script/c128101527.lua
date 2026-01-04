--환마의 파수꾼
--Guardian of the Phantom Demon
local s,id=GetID()
function s.initial_effect(c)
	--①: 덱에서 "삼환마" 1장을 묘지로 보내고 발동. 이 카드를 특수 소환하고, "실락원"을 발동한다.
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
	
	--②: 자신 필드에 "삼환마"가 존재하고 상대가 몬스터의 효과를 발동했을 때 발동(필드/묘지). 이 카드를 제외하고 무효로 한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.negcon)
	e2:SetCost(aux.bfgcost) -- 이 카드를 제외하고 발동하는 표준 코스트
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

--삼환마 및 실락원 리스트
s.listed_names={6007213,32491822,69890967,13301895}

--1번 효과 필터 및 로직
function s.sacredfilter(c)
	return c:IsCode(6007213,32491822,69890967) and c:IsAbleToGrave()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.sacredfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.sacredfilter,tp,LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.pandemoniumfilter(c,tp)
	return c:IsCode(13301895) and (c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD)) 
		and not c:IsForbidden()
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		--실락원을 덱/묘지에서 가져와 필드 존에 놓음
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.pandemoniumfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil,tp)
		local tc=g:GetFirst()
		if tc then
			Duel.BreakEffect()
			--기존 필드 마법 처리 후 발동
			local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
			if fc then
				Duel.SendtoGrave(fc,REASON_RULE)
				Duel.BreakEffect()
			end
			Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		end
	end
end

--2번 효과(무효화) 로직
function s.sacredcheck(c)
	return c:IsFaceup() and c:IsCode(6007213,32491822,69890967)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	--상대가 몬스터 효과를 발동했을 때 & 필드에 삼환마가 존재할 때
	return rp==1-tp and re:IsMonsterEffect() and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.sacredcheck,tp,LOCATION_MZONE,0,1,nil)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	--효과 발동 시점에 다시 한번 삼환마 존재 여부 확인(임의 선택 사항이나 안정성을 위함)
	if Duel.IsExistingMatchingCard(s.sacredcheck,tp,LOCATION_MZONE,0,1,nil) then
		Duel.NegateActivation(ev)
	end
end