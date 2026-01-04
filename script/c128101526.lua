--환마의 인도자 - 다크 서먼
--Guide of the Phantom Demon - Dark Summon
local s,id=GetID()
function s.initial_effect(c)
	--①: 패의 이 카드를 공개하고 발동. 덱에서 "삼환마"의 카드명이 기재된 마법/함정 1장을 세트하고, 이 카드를 특수 소환한다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.setcost)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	
	--②: 묘지의 이 카드를 제외하고 발동. 패 / 묘지에서 "삼환마" 1장을 소환 조건을 무시하고 특수 소환한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--삼환마 카드 번호 리스트 (초래신 스타일)
s.listed_names={6007213,32491822,69890967}

--1번 효과 로직
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
end

function s.setfilter(c)
	-- 초래신(DBB) 스타일의 필터링: 삼환마 본체 혹은 관련 마/함
	return (c:IsCode(6007213,32491822,69890967) or c:ListsCode(6007213,32491822,69890967))
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SSet(tp,g)>0 then
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

--2번 효과(특수 소환) 로직
function s.spfilter(c,e,tp)
	-- IsCanBeSpecialSummoned의 4번째 인자는 소환조건 무시, 5번째 인자는 소생제한 무시
	-- 라비엘이 묘지에서 나오려면 5번째 인자가 반드시 true여야 합니다.
	return c:IsCode(6007213,32491822,69890967) 
		and c:IsCanBeSpecialSummoned(e,0,tp,true,true) 
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	-- 묘지 대응을 위해 NecroValleyFilter 사용
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		-- 여기서도 7번째 인자를 true로 주어 소생 제한 룰을 무시합니다.
		Duel.SpecialSummon(g,0,tp,tp,true,true,POS_FACEUP)
	end
end