--Mist Valley Hero Georgias
local s,id=GetID()
function s.initial_effect(c)
	--(1) If you control a "Mist Valley" monster, SS this card from hand in Defense Position
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- (1) 효과 명칭 1턴 1번
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)
	--(2) NS/SS 성공시 : 레벨5 이하 "Mist Valley" SS (+옵션 코스트 시 서치)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1}) -- (2) 효과 명칭 1턴 1번
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
	--(3) Quick Effect: 상대가 카드/효과 발동 시, "Mist Valley" 싱크로 소환
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.syncon)
	e4:SetTarget(s.syntg)
	e4:SetOperation(s.synop)
	c:RegisterEffect(e4)
end

--------------------------------
-- (1) 패에서 자신 수비표시 특소
--------------------------------
function s.mvmonfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MIST_VALLEY)
end
function s.hspcon(e,tp,eg,ep,ev,re,r,rp)
	-- "Mist Valley" 몬스터를 컨트롤하고 있어야 함
	return Duel.IsExistingMatchingCard(s.mvmonfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.hsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.hspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
end

--------------------------------
-- (2) NS/SS 시 레벨5 이하 "Mist Valley" 특소 + 옵션 패 1장 코스트 → 마법/함정 서치
--------------------------------
function s.mvspfilter(c,e,tp)
	return c:IsSetCard(SET_MIST_VALLEY) and c:IsLevelBelow(5)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.mvstfilter(c)
	return c:IsSetCard(SET_MIST_VALLEY) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

-- 코스트: 패 1장 버릴지 여부 선택, 버리면 Label=1, 아니면 0
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- 옵션 코스트라서 항상 통과
	e:SetLabel(0)
	local hg=Duel.GetMatchingGroup(Card.IsAbleToGraveAsCost,tp,LOCATION_HAND,0,nil)
	if #hg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local cg=hg:Select(tp,1,1,nil)
		if #cg>0 then
			Duel.SendtoGrave(cg,REASON_COST)
			e:SetLabel(1) -- 코스트 지불했음을 표시
		end
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		return Duel.IsExistingMatchingCard(s.mvspfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
	-- 코스트를 지불했다면 "Mist Valley" 마/함도 서치 가능하므로 정보만 올려둠
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	-- 레벨 5 이하 "Mist Valley" 특소
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.mvspfilter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g==0 then return end
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- 코스트를 지불했으면 "Mist Valley" 마/함 서치
	if e:GetLabel()==1 then
		local sg=Duel.GetMatchingGroup(s.mvstfilter,tp,LOCATION_DECK,0,nil)
		if #sg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local tg=sg:Select(tp,1,1,nil)
			if #tg>0 then
				Duel.SendtoHand(tg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,tg)
			end
		end
	end
end

--------------------------------
-- (3) 상대 효과 발동시 "Mist Valley" 싱크로 소환
--------------------------------
function s.syncon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대가 카드/효과를 발동했을 때
	return rp==1-tp
end
function s.synfilter(c)
	return c:IsSetCard(SET_MIST_VALLEY) and c:IsType(TYPE_SYNCHRO)
		and c:IsSynchroSummonable(nil)
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local sc=g:GetFirst()
	if sc then
		-- 몬스터 존의 몬스터들만 소재로 사용해서 "Mist Valley" 싱크로 소환
		Duel.SynchroSummon(tp,sc,nil)
	end
end
