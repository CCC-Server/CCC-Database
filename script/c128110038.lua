-- 파괴수결전 - 싱귤러 포인트
local s,id=GetID()
local CODE_WATERFRONT=56111151 -- KYOUTOU 워터프론트

function s.initial_effect(c)
	-- ①: 발동 시 처리 (서치 + 조건부 특소)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ②: 묘지 되돌리고 공뻥 + 효과 복사
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.effcon)
	e2:SetCost(s.effcost)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end
s.listed_names={CODE_WATERFRONT}
s.listed_series={SET_KAIJU, 0xc82} -- 파괴수, 대괴수결전병기
s.counter_list={COUNTER_KAIJU}

-- ① 효과
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_HAND)
end
function s.thfilter(c)
	return ((c:IsSetCard(SET_KAIJU) and c:IsSpellTrap()) or (c:IsSetCard(0xc82) and c:IsMonster())) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return (c:IsSetCard(0xc82) or c:IsSetCard(SET_KAIJU)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		if Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
		    Duel.ConfirmCards(1-tp,sg)
            if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
				and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
				if #sg>0 then
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
				end
			end
        end
	end
end

-- ② 효과
local hardcoded_code_table = {
	-- ② 효과로 복사할 수 없는 몬스터 목록
	84769941,	--대파괴수용결전병기 슈퍼메카도고란
	0	--(카드 없음)
}

function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CODE_WATERFRONT),tp,LOCATION_ONFIELD,0,1,nil)
end

function s.tdfilter(c)
	return c:IsSetCard(SET_KAIJU) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeckAsCost()
end
function s.effcost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 코스트 지불 여부에 따라 효과 처리 적용 가능성이 달라지는 효과는, 코스트가 아닌 타겟 함수에서 코스트 처리를 실행해야 함
	e:SetLabel(1)
	return true
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		if e:GetLabel()==0 then return false end
		e:SetLabel(0)
		return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local tc=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil):GetFirst()
	Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_COST)
	e:SetLabel(tc:GetOriginalCode())
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. 공격력 증가
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,SET_KAIJU))
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetValue(800)
	e1:SetReset(RESETS_STANDARD_PHASE_END,2)
	Duel.RegisterEffect(e1,tp)

	-- 2. 효과 복사
	local code=e:GetLabel()
	for k,v in pairs(hardcoded_code_table) do
		if code==v then return end
	end
	Card.CopyEffect(c,code,RESETS_STANDARD_PHASE_END,2)

	-- 3. 범위 보정
	local effs={c:GetOwnEffects()}
	for _,eff in ipairs(effs) do
		if eff:GetOwner()==e:GetOwner() and not eff:IsHasProperty(EFFECT_FLAG_INITIAL) then
			if eff:GetRange()&LOCATION_MZONE>0 then
				-- Change Range
				eff:SetRange((eff:GetRange()&~LOCATION_MZONE)|LOCATION_SZONE)
				-- Todo from here
				local cost=eff:GetCost() or aux.TRUE
				local tg=eff:GetTarget() or aux.TRUE
				local op=eff:GetOperation() or aux.TRUE
				
			else
				eff:SetRange(eff:GetRange()&~LOCATION_SZONE)
			end
		end
	end
end
