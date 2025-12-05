--ＢＦ－？？？ (임시 이름)
--Blackwing - ??? (temp)
local s,id=GetID()
local CARD_BLACK_WHIRLWIND=91351370
function s.initial_effect(c)
	--① 이 카드를 공개하고 발동: 덱/묘지에서 "검은 선풍"을 앞면으로 놓고,
	--그 후 "BF" 몬스터 1장을 일반 소환할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SUMMON) -- ★ CATEGORY_TOFIELD 제거
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- ①: 이 카드명 1턴 1번
	e1:SetCost(s.whcost)
	e1:SetTarget(s.whtg)
	e1:SetOperation(s.whop)
	c:RegisterEffect(e1)

	--② 묘지에서 발동: 자신 필드에 "BF" 싱크로 또는 "블랙 페더 드래곤"이 있으면,
	--이 카드를 레벨 4 몬스터로서 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- ②: 이 카드명 1턴 1번
	e2:SetCondition(s.gyspcon)
	e2:SetTarget(s.gysptg)
	e2:SetOperation(s.gyspop)
	c:RegisterEffect(e2)
end

-- 세트/관련 카드
s.listed_series={SET_BLACKWING}
s.listed_names={CARD_BLACK_WHIRLWIND,CARD_BLACK_WINGED_DRAGON}

--------------------------------
-- ① "검은 선풍" 놓고 BF 일반 소환
--------------------------------

-- 코스트 : 이 카드를 상대에게 보여준다
function s.whcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	Duel.ConfirmCards(1-tp,c)
	Duel.ShuffleHand(tp)
end

function s.whfilter(c)
	return c:IsCode(CARD_BLACK_WHIRLWIND) and not c:IsForbidden()
end

function s.whtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.whfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	-- 일반 소환은 "실행할 수 있다"라서 가능성만 표시
	Duel.SetPossibleOperationInfo(0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.nsfilter(c)
	return c:IsSetCard(SET_BLACKWING) and c:IsSummonable(true,nil)
end

function s.whop(e,tp,eg,ep,ev,re,r,rp)
	-- "검은 선풍"을 앞면으로 놓기
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.whfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
	-- 그 후, "BF" 몬스터 1장의 일반 소환을 실행할 수 있다.
	if Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		local sc=sg:GetFirst()
		if sc then
			Duel.Summon(tp,sc,true,nil)
		end
	end
end

--------------------------------
-- ② 묘지에서 자기 자신 특수 소환 (레벨 4로)
--------------------------------

function s.confilter(c)
	return c:IsFaceup()
		and ((c:IsSetCard(SET_BLACKWING) and c:IsType(TYPE_SYNCHRO)) or c:IsCode(CARD_BLACK_WINGED_DRAGON))
end

function s.gyspcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.gysptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.gyspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 레벨 4로 취급
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(4)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
