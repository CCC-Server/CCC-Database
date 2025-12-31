-- 파괴수결전 - 싱귤러 포인트
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터
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
s.listed_series={0xd3, 0xc82} -- 파괴수, 대괴수결전병기
s.counter_list={COUNTER_KAIJU}

-- ① 효과
function s.thfilter(c)
	return ((c:IsSetCard(0xd3) and c:IsType(TYPE_SPELL+TYPE_TRAP)) or c:IsSetCard(0xc82)) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return (c:IsSetCard(0xc82) or c:IsSetCard(0xd3)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_HAND)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,g)
			if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
				and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
				and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) 
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
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

local hardcoded_code_table = {
	-- ② 효과로 복사할 수 없는 몬스터 목록
	84769941,	--Super Anti-Kaiju War Machine Mecha-Dogoran
	0	--해당하는 카드가 없음
}

-- ② 효과: 조건 수정됨 (LOCATION_FZONE 추가)
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,CODE_WATERFRONT),tp,LOCATION_ONFIELD,0,1,nil)
end

function s.tdfilter(c)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeckAsCost()
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
		e:SetLabelObject(nil)
		return true
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local tc=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil):GetFirst()
	Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_COST)
	e:SetLabelObject(tc)
	e:SetLabel(tc:GetOriginalCode())
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. 공격력 증가
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetValue(800)
	e1:SetReset(RESETS_STANDARD_PHASE_END,2)
	Duel.RegisterEffect(e1,tp)

	-- 2. 효과 복사
	local code=e:GetLabel()
	for k,v in pairs(hardcoded_code_table) do
		if code==v then return end
	end
	Duel.MajesticCopy(c,e:GetLabelObject())

	-- 3. 범위 보정
	-- 함수 내 함수 선언에서는 변수명 겹침에 유의
	local effs={c:GetOwnEffects()}
	local result=false
	local card_iscanremovecounter=Card.IsCanRemoveCounter
	local duel_iscanremovecounter=Duel.IsCanRemoveCounter
	Card.IsCanRemoveCounter=function(tc,p,countertype,ct,reason)
		if reason&REASON_COST>0 then result=true end
		return card_iscanremovecounter(tc,p,countertype,ct,reason)
	end
	Duel.IsCanRemoveCounter=function(p,s,o,countertype,ct,reason)
		if reason&REASON_COST>0 then result=true end
		return duel_iscanremovecounter(p,s,o,countertype,ct,reason)
	end
	for _,eff in ipairs(effs) do
		result=false
		if eff:GetOwner()==e:GetOwner() and not eff:IsHasProperty(EFFECT_FLAG_INITIAL) then
			local cost=eff:GetCost()
			local tg=eff:GetTarget()
			if cost and type(cost)=="function" then eff:cost(PLAYER_NONE,nil,PLAYER_NONE,nil,inl,0,PLAYER_NONE,0) end
			if tg and type(tg)=="function" then eff:tg(PLAYER_NONE,nil,PLAYER_NONE,nil,inl,0,PLAYER_NONE,0) end
			if result then
				-- 이 효과는 코스트로 카운터를 제거함
				local range=eff:GetRange()
				if range&LOCATION_MZONE>0 then
					-- 이 효과는 몬스터 존에서 발동되는 효과
					eff:SetRange((range|LOCATION_SZONE)&~LOCATION_MZONE)
					-- 지속물 처리 추가
					if not tg or type(tg)~="function" then tg=aux.TRUE end
					eff:SetTarget(function(te,te_tp,te_eg,te_ep,te_ev,te_re,te_r,te_rp,te_chk)
						if te_chk==0 then return te:tg(te_tp,te_eg,te_ep,te_ev,te_re,te_r,te_rp,0) end
						te:tg(te_tp,te_eg,te_ep,te_ev,te_re,te_r,te_rp,1)
						-- 코스트 지불 후 지속물이 남아 있고, 한편으로 효과 처리시에 남아 있지 않으면, 자동 불발
						if te:GetHandler():IsOnField() then
							local f=te:GetOperation()
							if not f or type(f)~="function" then f=aux.TRUE end
							te:SetOperation(function(...)
								if not te:GetHandler():IsRelateToEffect(te) then return end
								f(...)
							end)
						end
					end)
				else
					-- 이 효과는 몬스터 존에서 발동하지 않음
					eff:Reset()
				end
			else
				-- 이 효과는 코스트로 카운터를 제거하지 않음
				eff:Reset()
			end
		end
	end
	Card.IsCanRemoveCounter=card_iscanremovecounter
	Duel.IsCanRemoveCounter=duel_iscanremovecounter
end
