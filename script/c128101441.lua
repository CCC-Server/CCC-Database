-- 종이 비행기 - 긴급 이륙
local s,id=GetID()
function s.initial_effect(c)
	-- "Paper Plane" 카드군 (0xc53)
	s.listed_series={0xc53}

	-- ①: 장착 상태의 몬스터 특수 소환 + 상대 카드 1장 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE) -- 마법 카드의 발동
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,{id,0})
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 묘지 효과 (상대 효과 발동 시 제외하고 샐비지)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--------------------------------
-- ① 장착된 몬스터 특소 + 상대 카드 파괴
--------------------------------
function s.spfilter(c,e,tp)
	-- [수정 핵심] "원래 유니온인가?"(TYPE_UNION)를 체크하면,
	-- DB에 유니온 아이콘이 없거나 효과로 장착된 일반 몬스터는 선택 불가능합니다.
	-- 따라서 "장착 상태(TYPE_EQUIP)"인 "몬스터(Original Type Monster)"라면 모두 가능하게 수정했습니다.
	return c:IsFaceup()
		and c:IsLocation(LOCATION_SZONE)
		and c:GetEquipTarget()~=nil         -- 누군가에게 장착되어 있는가
		and c:IsOriginalType(TYPE_MONSTER)  -- 원래 정체는 몬스터인가
		and c:IsType(TYPE_EQUIP)            -- 지금 장착 카드 취급인가
		and c:IsControler(tp)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp)
			and s.spfilter(chkc,e,tp)
	end
	if chk==0 then
		-- 몬스터 존이 비어있고, 특수 소환 가능한 장착 몬스터가 있어야 함
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_SZONE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_SZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
	-- 파괴 효과는 '가능성'만 있으면 인포를 잡거나, 확정일 때만 잡음 (여기선 조건부라 생략 가능하나 추가함)
	local g_des=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	if #g_des>0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,g_des,1,0,0)
	end
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	-- 장착 상태 몬스터 특수 소환
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 특소 성공 시, 상대 필드의 카드 1장 파괴
		local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
		if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then -- 파괴할지 선택 (강제면 SelectYesNo 제거)
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local dg=g:Select(tp,1,1,nil)
			Duel.HintSelection(dg)
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
end

--------------------------------
-- ② 묘지 효과
--------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp -- 상대가 발동했을 때
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end
function s.thfilter(c)
	return c:IsSetCard(0xc53)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end