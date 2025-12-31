--SU(서브유니즌) 옐로우테일 샤워
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소재 불가
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	e0:SetValue(1)
	c:RegisterEffect(e0)
	--①: 묘지 특수 소환 및 융합 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)
	--②: 위치 이동 및 배틀 페이즈 봉쇄
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.mvtg)
	e2:SetOperation(s.mvop)
	c:RegisterEffect(e2)
	--③: 같은 세로열 이외의 필드 발동 효과 내성
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
end

--① 효과 처리
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		-- 융합 가능한 몬스터가 엑스트라 덱에 있는지 대략적으로 확인
		and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_EXTRA,0,1,nil,0xc81)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_FUSION_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. 묘지에서 특수 소환
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- 2. 융합 소환 처리
		-- 특수 소환된 이 카드가 필드에 존재해야 함
		if not c:IsLocation(LOCATION_MZONE) or c:IsFacedown() then return end
		
		-- 융합 소재: 자신 패 + 자신 필드 (이 카드 포함)
		local mg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		
		-- '이 카드(c)'를 반드시 포함하여 융합 가능한 'SU' 융합 몬스터 확인
		local sg=Duel.GetMatchingGroup(function(tc,mg,c,tp)
			return tc:IsType(TYPE_FUSION) and tc:IsSetCard(0xc81) and tc:CheckFusionMaterial(mg,c,tp)
		end,tp,LOCATION_EXTRA,0,nil,mg,c,tp)
		
		if #sg>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc=sg:Select(tp,1,1,nil):GetFirst()
			
			if tc then
				-- 융합 소재 선택 (CheckFusionMaterial의 2번째 인자로 c를 넘겨 강제 지정)
				tc:SetMaterial(nil)
				local mat=Duel.SelectFusionMaterial(tp,tc,mg,c,tp)
				tc:SetMaterial(mat)
				
				-- 소재 묘지로 보내고 융합 소환
				Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				Duel.BreakEffect()
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
	end
end

--② 효과 처리
function s.mvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)>0 end
end

function s.mvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) or Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_CONTROL)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOZONE)
	-- [수정] 변수명 충돌 방지: local s -> local zone
	local zone=Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0)
	-- [수정] 정수형 변환 보장: math.floor 추가
	local nseq=math.floor(math.log(zone,2))
	Duel.MoveSequence(c,nseq)
	
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetCondition(s.actcon)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.actcon(e)
	return Duel.IsBattlePhase()
end

--③ 효과 처리
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetHandler()
	local loc=te:GetActivateLocation()
	return (loc&LOCATION_ONFIELD)~=0 and te:GetOwnerPlayer()~=e:GetHandlerPlayer() and not c:GetColumnGroup():IsContains(tc)
end